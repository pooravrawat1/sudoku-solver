const $ = (id) => document.getElementById(id);
let fixtures = {}, original = [], values = [], traceInput = [], events = [], position = 0;
let selected = -1, timer = null, busy = false, domains = null, search = false, changed = [], undone = -1;
const cells = [];
const names = {easy: 'Easy puzzle', hard: 'Hard puzzle', search: 'Backtracking demo', unsolvable: 'No-solution example', solved: 'Completed example', custom: 'Custom board'};

for (let i = 0; i < 81; i++) {
  const cell = document.createElement('button');
  cell.className = 'cell';
  cell.addEventListener('click', () => { selected = i; render(); });
  cell.addEventListener('keydown', (event) => {
    const moves = {ArrowLeft: -1, ArrowRight: 1, ArrowUp: -9, ArrowDown: 9};
    if (event.key in moves) {
      event.preventDefault(); selected = Math.max(0, Math.min(80, i + moves[event.key]));
      render(); cells[selected].focus();
    } else if (/^[1-9]$/.test(event.key) || ['Backspace', 'Delete', '0'].includes(event.key)) {
      event.preventDefault(); enter(/^[1-9]$/.test(event.key) ? Number(event.key) : 0);
    }
  });
  cells.push(cell); $('board').append(cell);
}
for (const digit of [1,2,3,4,5,6,7,8,9,0]) {
  const button = document.createElement('button');
  button.textContent = digit || 'Erase'; button.setAttribute('aria-label', digit ? `Enter ${digit}` : 'Erase cell');
  button.addEventListener('click', () => enter(digit)); $('number-pad').append(button);
}

function peers(a, b) {
  return Math.floor(a/9) === Math.floor(b/9) || a%9 === b%9 ||
    (Math.floor(a/27) === Math.floor(b/27) && Math.floor(a%9/3) === Math.floor(b%9/3));
}
function conflicts() {
  return values.map((v, i) => v !== 0 && values.some((w, j) => i !== j && v === w && peers(i,j)));
}
function render() {
  const errors = events.length ? [] : conflicts();
  const activeCell = selected >= 0 ? selected : undone >= 0 ? undone : changed[0];
  document.querySelectorAll('.coordinates span').forEach((label, column) => {
    label.classList.toggle('active', activeCell !== undefined && activeCell % 9 === column);
  });
  document.querySelectorAll('.row-coordinates span').forEach((label, row) => {
    label.classList.toggle('active', activeCell !== undefined && Math.floor(activeCell / 9) === row);
  });
  cells.forEach((cell, i) => {
    const given = (events.length ? traceInput : original)[i];
    cell.className = ['cell', given ? 'given' : '', selected >= 0 && peers(i, selected) ? 'peer' : '',
      events.length && !given && values[i] ? 'prolog' : '', changed.includes(i) ? 'changed' : '',
      i === undone ? 'undone' : '', i === selected ? 'selected' : '', errors[i] ? 'conflict' : ''].filter(Boolean).join(' ');
    cell.replaceChildren();
    if (values[i]) cell.textContent = values[i];
    else if (domains && !search) {
      const grid = document.createElement('span'); grid.className = 'candidates'; grid.setAttribute('aria-hidden', 'true');
      for (let n = 1; n <= 9; n++) {
        const number = document.createElement('span'); number.textContent = domains[i].includes(n) ? n : '';
        grid.append(number);
      }
      cell.append(grid);
    }
    cell.setAttribute('aria-label', `Row ${Math.floor(i/9)+1}, column ${i%9+1}: ${values[i] || 'empty'}${given ? ', given' : ''}`);
    cell.setAttribute('aria-pressed', String(i === selected));
    cell.disabled = busy;
  });
  $('filled').textContent = `${values.filter(Boolean).length} / 81 filled`;
  $('cell-label').textContent = selected < 0 ? 'CELL INSPECTOR' : `ROW ${Math.floor(selected/9)+1} · COLUMN ${selected%9+1}`;
  $('cell-detail').textContent = selected < 0 ? 'Select a square to inspect its value and domain.' : values[selected] ?
    `Value = ${values[selected]}${(events.length ? traceInput : original)[selected] ? ' · given clue' : ' · bound cell'}` :
    domains && !search ? `Domain = { ${domains[selected].join(', ')} }` : search ?
    'Unbound. Domain snapshots are shown before labeling.' : 'Empty cell · enter a digit to make a move.';
  $('progress').max = events.length; $('progress').value = position;
  $('progress').disabled = !events.length || busy;
  $('progress-label').textContent = `${position} / ${events.length}`;
  $('step').disabled = busy || !events.length || position >= events.length;
  $('rewind').disabled = busy || !events.length;
  $('puzzle').disabled = busy; $('edit-clues').disabled = busy || !!events.length;
  $('check').disabled = busy || !!events.length; $('reset').disabled = busy;
  $('number-pad').querySelectorAll('button').forEach(b => b.disabled = busy || !!events.length);
  $('solve').disabled = busy;
  $('solve').querySelector('span').textContent = busy ? 'Recording…' : timer ? 'Pause' : events.length ? position === events.length ? 'Replay' : 'Play' : 'Watch Prolog';
}
function pause() { clearTimeout(timer); timer = null; }
function clearTrace() {
  pause(); events = []; position = 0; domains = null; search = false; changed = []; undone = -1;
  $('journal').innerHTML = '<div class="empty-journal"><h3>No execution recorded.</h3><p>Start the solver to inspect each constraint and the variable bindings that follow.</p><p>Choose <b>Backtracking demo</b> to see Prolog undo bindings during search.</p></div>';
  $('event-count').textContent = '00 EVENTS'; $('backtrack-count').textContent = '0 BACKTRACKS';
  $('phase').textContent = 'Ready'; $('playback-label').textContent = 'Ready to record';
}
function loadPuzzle() {
  clearTrace(); const kind = $('puzzle').value;
  original = kind === 'custom' ? Array(81).fill(0) : fixtures[kind].flat();
  values = [...original]; selected = -1;
  $('edit-clues').checked = kind === 'custom'; $('puzzle-title').textContent = names[kind];
  $('game-message').textContent = 'Select a cell and type 1–9. Backspace erases a move.'; render();
}
function enter(value) {
  if (busy || events.length) return;
  if (selected < 0) { $('game-message').textContent = 'Select a square first.'; return; }
  if (original[selected] && !$('edit-clues').checked) { $('game-message').textContent = 'This is a given clue. Enable Edit clues to change it.'; return; }
  values[selected] = value;
  if ($('edit-clues').checked) original[selected] = value;
  $('game-message').textContent = conflicts().some(Boolean) ? 'Highlighted digits conflict in a row, column, or box.' : 'Move entered. Keep playing or let Prolog take it from here.';
  render();
}
function applyEvent(event) {
  const previous = [...values]; undone = -1;
  if (event.domains) {
    domains = event.domains.flat(); values = domains.map(d => d.length === 1 ? d[0] : 0);
  }
  if (event.type === 'search') search = true;
  if (event.cell !== undefined) { values[event.cell] = event.value; if (event.type === 'backtrack') undone = event.cell; }
  if (event.board) values = event.board.flat();
  if (['unsolvable', 'invalid'].includes(event.type)) { domains = null; search = false; }
  changed = values.flatMap((v, i) => v !== previous[i] ? [i] : []);
}
function eventMessage(event) {
  if (event.message) return event.message;
  const location = `R${Math.floor(event.cell/9)+1}C${event.cell%9+1}`;
  return event.type === 'bind' ? `${location} = ${event.value}. A logic variable is bound during labeling.` : `${location} is unbound again. Prolog rolls back this binding.`;
}
function paintJournal() {
  const journal = $('journal'); journal.replaceChildren();
  // Keep the DOM bounded; the scrubber still reaches every event.
  const start = Math.max(0, position - 160);
  if (start) { const note = document.createElement('p'); note.textContent = `Showing the latest 160 events. Scrub backward to inspect earlier ones.`; note.className = 'game-message'; journal.append(note); }
  events.slice(start, position).forEach((event, index) => {
    const row = document.createElement('div'); row.className = `event ${event.type}`;
    const number = document.createElement('span'); number.className = 'event-number'; number.textContent = String(start+index+1).padStart(2,'0');
    const content = document.createElement('div'); const kind = document.createElement('span'); kind.className = 'event-kind'; kind.textContent = event.type;
    content.append(kind, document.createTextNode(eventMessage(event)));
    if (event.cell !== undefined) {
      const reference = document.createElement('button');
      reference.className = 'cell-reference';
      reference.textContent = `Inspect R${Math.floor(event.cell/9)+1}C${event.cell%9+1}`;
      reference.addEventListener('click', () => { pause(); selected = event.cell; render(); });
      content.append(reference);
    }
    row.append(number, content); journal.append(row);
  });
  journal.scrollTop = journal.scrollHeight;
  $('event-count').textContent = `${String(position).padStart(2,'0')} EVENTS`;
  $('backtrack-count').textContent = `${events.slice(0,position).filter(e => e.type === 'backtrack').length} BACKTRACKS`;
  const event = events[position-1];
  $('phase').textContent = event ? ({solved:'Solved', invalid:'Invalid', unsolvable:'No solution', search:'Search', bind:'Search', backtrack:'Backtrack'}[event.type] || 'Propagation') : 'Ready';
  $('playback-label').textContent = event ? eventMessage(event) : 'Recorded · ready to play';
}
function seek(target) {
  values = [...traceInput]; domains = null; search = false; changed = []; undone = -1;
  for (let i=0; i<target; i++) applyEvent(events[i]);
  position = target; paintJournal(); render();
}
function step() {
  if (position >= events.length) { pause(); render(); return; }
  applyEvent(events[position++]); paintJournal();
  if (position === events.length) pause();
  render();
}
function play() {
  if (position === events.length) seek(0);
  const tick = () => { step(); if (position < events.length) timer = setTimeout(tick, Number($('speed').value)); render(); };
  timer = setTimeout(tick, 0); render();
}
$('solve').addEventListener('click', async () => {
  if (timer) { pause(); render(); return; }
  if (events.length) { play(); return; }
  busy = true; render(); $('game-message').textContent = 'Recording an actual Prolog run…';
  traceInput = [...values];
  try {
    const board = Array.from({length:9}, (_,r) => traceInput.slice(r*9,r*9+9));
    const response = await fetch('/api/trace', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({board})});
    const data = await response.json(); if (!response.ok) throw new Error(data.error || 'Could not record the trace.');
    events = data.events; position = 0; busy = false;
    $('game-message').textContent = 'Recorded from Prolog. Pause, step, or scrub to explore. Reset to play again.';
    play();
  } catch (error) { busy = false; $('game-message').textContent = error.message; render(); }
});
$('step').addEventListener('click', () => { pause(); step(); });
$('rewind').addEventListener('click', () => { pause(); seek(0); });
$('progress').addEventListener('input', () => { pause(); seek(Number($('progress').value)); });
$('puzzle').addEventListener('change', loadPuzzle);
$('reset').addEventListener('click', () => { clearTrace(); values = [...original]; $('game-message').textContent = 'Puzzle reset. Select a square to play.'; render(); });
$('check').addEventListener('click', () => {
  $('game-message').textContent = conflicts().some(Boolean) ? 'There are conflicting digits. Check the highlighted cells.' : values.every(Boolean) ? 'Solved! Every row, column, and box contains 1–9.' : 'No direct conflicts so far. The board is not complete yet.';
  render();
});
async function initialize() {
  busy = true; values = Array(81).fill(0); original = [...values]; render();
  try {
    const response = await fetch('/api/puzzles'); if (!response.ok) throw new Error('Could not load puzzles.');
    fixtures = await response.json(); busy = false; loadPuzzle();
  } catch (error) { $('game-message').textContent = `${error.message} Start the Python server, then reload this page.`; }
}
initialize();
