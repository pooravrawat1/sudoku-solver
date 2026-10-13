const $ = (id) => document.getElementById(id);
let fixtures = {}, original = [], values = [], traceInput = [], events = [], position = 0;
let selected = -1, timer = null, busy = false, domains = null, search = false, changed = [], undone = -1;
const cells = [];
const names = {easy: 'easy puzzle', hard: 'hard puzzle', search: 'backtracking demo', unsolvable: 'no-solution example', solved: 'completed example', custom: 'custom board'};

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
  button.textContent = digit || 'erase'; button.setAttribute('aria-label', digit ? `enter ${digit}` : 'erase cell');
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
    cell.setAttribute('aria-label', `row ${Math.floor(i/9)+1}, column ${i%9+1}: ${values[i] || 'empty'}${given ? ', given' : ''}`);
    cell.setAttribute('aria-pressed', String(i === selected));
    cell.disabled = busy;
  });
  $('filled').textContent = `${values.filter(Boolean).length} / 81 filled`;
  $('cell-label').textContent = selected < 0 ? 'cell inspector' : `row ${Math.floor(selected/9)+1} · column ${selected%9+1}`;
  $('cell-detail').textContent = selected < 0 ? 'select a square to inspect its value and domain.' : values[selected] ?
    `value = ${values[selected]}${(events.length ? traceInput : original)[selected] ? ' · given clue' : ' · bound cell'}` :
    domains && !search ? `domain = { ${domains[selected].join(', ')} }` : search ?
    'unbound. domain snapshots are shown before labeling.' : 'empty cell · enter a digit to make a move.';
  $('progress').max = events.length; $('progress').value = position;
  $('progress').disabled = !events.length || busy;
  $('progress-label').textContent = `${position} / ${events.length}`;
  $('step').disabled = busy || !events.length || position >= events.length;
  $('rewind').disabled = busy || !events.length;
  $('puzzle').disabled = busy; $('edit-clues').disabled = busy || !!events.length;
  $('check').disabled = busy || !!events.length; $('reset').disabled = busy;
  $('number-pad').querySelectorAll('button').forEach(b => b.disabled = busy || !!events.length);
  $('solve').disabled = busy;
  $('solve').querySelector('span').textContent = busy ? 'recording…' : timer ? 'pause' : events.length ? position === events.length ? 'replay' : 'play' : 'watch prolog';
}
function pause() { clearTimeout(timer); timer = null; }
function clearTrace() {
  pause(); events = []; position = 0; domains = null; search = false; changed = []; undone = -1;
  $('journal').innerHTML = '<div class="empty-journal"><h3>no execution recorded.</h3><p>start the solver to see the constraints and bindings as they happen.</p></div>';
  $('event-count').textContent = '00 events'; $('backtrack-count').textContent = '0 backtracks';
  $('phase').textContent = 'ready'; $('playback-label').textContent = 'ready to record';
}
function loadPuzzle() {
  clearTrace(); const kind = $('puzzle').value;
  original = kind === 'custom' ? Array(81).fill(0) : fixtures[kind].flat();
  values = [...original]; selected = -1;
  $('edit-clues').checked = kind === 'custom'; $('puzzle-title').textContent = names[kind];
  $('game-message').textContent = 'select a cell and type 1–9. backspace erases a move.'; render();
}
function enter(value) {
  if (busy || events.length) return;
  if (selected < 0) { $('game-message').textContent = 'select a square first.'; return; }
  if (original[selected] && !$('edit-clues').checked) { $('game-message').textContent = 'this is a given clue. enable edit clues to change it.'; return; }
  values[selected] = value;
  if ($('edit-clues').checked) original[selected] = value;
  $('game-message').textContent = conflicts().some(Boolean) ? 'highlighted digits conflict in a row, column, or box.' : 'move entered. keep playing or let prolog take it from here.';
  render();
}
function applyEvent(event) {
  const previous = [...values]; undone = -1;
  if (event.domains) {
    domains = event.domains.flat(); values = domains.map(d => d.length === 1 ? d[0] : 0);
  }
  if (event.type === 'search') search = true;
  if (['bind', 'backtrack'].includes(event.type)) {
    values[event.cell] = event.value;
    if (event.type === 'backtrack') undone = event.cell;
  }
  if (event.board) values = event.board.flat();
  if (['unsolvable', 'invalid'].includes(event.type)) { domains = null; search = false; }
  changed = values.flatMap((v, i) => v !== previous[i] ? [i] : []);
}
function eventMessage(event) {
  if (event.message) return event.message.toLowerCase();
  const location = `r${Math.floor(event.cell/9)+1}c${event.cell%9+1}`;
  if (event.type === 'bind') {
    return `${location} = ${event.value}; a binding observed during labeling([ffc]).`;
  }
  if (event.target?.cell !== undefined) {
    const target = `r${Math.floor(event.target.cell/9)+1}c${event.target.cell%9+1}`;
    return `undo ${location}; return to ${target} and exclude ${event.target.excluded}.`;
  }
  return event.target?.exhausted ?
    `undo ${location}; labeling([ffc]) has no choice left to retry.` :
    `undo ${location}; labeling is unwinding toward a choice point.`;
}
async function showRule(event) {
  const name = event.target?.rule || event.rule;
  if (!name) return;
  pause(); render();
  $('rule-title').textContent = name;
  $('rule-context').textContent = eventMessage(event);
  $('rule-location').textContent = 'loading source…';
  $('rule-code').textContent = '';
  $('rule-dialog').showModal();
  try {
    const response = await fetch(`/api/rule?name=${encodeURIComponent(name)}`);
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'source unavailable.');
    $('rule-location').textContent = `${data.file}:${data.line}`;
    $('rule-code').textContent = data.source;
  } catch (error) {
    $('rule-location').textContent = 'source unavailable';
    $('rule-code').textContent = error.message.toLowerCase();
  }
}
function paintJournal() {
  const journal = $('journal'); journal.replaceChildren();
  // Keep the DOM bounded; the scrubber still reaches every event.
  const start = Math.max(0, position - 160);
  if (start) { const note = document.createElement('p'); note.textContent = `showing the latest 160 events. scrub backward to inspect earlier ones.`; note.className = 'game-message'; journal.append(note); }
  events.slice(start, position).forEach((event, index) => {
    const row = document.createElement('div'); row.className = `event ${event.type}${index === position - start - 1 ? ' is-current' : ''}`;
    const number = document.createElement('span'); number.className = 'event-number'; number.textContent = String(start+index+1).padStart(2,'0');
    const content = document.createElement('div');
    const heading = document.createElement('div'); heading.className = 'event-heading';
    const kind = document.createElement('span'); kind.className = 'event-kind'; kind.textContent = event.type;
    const rule = document.createElement('button'); rule.className = 'event-rule';
    rule.type = 'button'; rule.textContent = event.target?.rule || event.rule || '';
    rule.setAttribute('aria-label', `show source for ${rule.textContent}`);
    rule.addEventListener('click', () => showRule(event));
    heading.append(kind, rule);
    content.append(heading, document.createTextNode(eventMessage(event)));
    if (event.cell !== undefined) {
      const reference = document.createElement('button');
      reference.className = 'cell-reference';
      reference.textContent = `inspect r${Math.floor(event.cell/9)+1}c${event.cell%9+1}`;
      reference.addEventListener('click', () => { pause(); selected = event.cell; render(); });
      content.append(reference);
    }
    row.append(number, content); journal.append(row);
  });
  journal.scrollTop = journal.scrollHeight;
  $('event-count').textContent = `${String(position).padStart(2,'0')} events`;
  $('backtrack-count').textContent = `${events.slice(0,position).filter(e => e.type === 'backtrack').length} backtracks`;
  const event = events[position-1];
  $('phase').textContent = event ? ({rule:'setup', solved:'solved', invalid:'invalid', unsolvable:'no solution', search:'search', choice:'choice', bind:'search', backtrack:'backtrack', retry:'backtrack'}[event.type] || 'propagation') : 'ready';
  $('playback-label').textContent = event ? eventMessage(event) : 'recorded · ready to play';
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
  busy = true; render(); $('game-message').textContent = 'recording an actual prolog run…';
  traceInput = [...values];
  try {
    const board = Array.from({length:9}, (_,r) => traceInput.slice(r*9,r*9+9));
    const response = await fetch('/api/trace', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({board})});
    const data = await response.json(); if (!response.ok) throw new Error(data.error || 'could not record the trace.');
    events = data.events; position = 0; busy = false;
    $('game-message').textContent = 'recorded from prolog. pause, step, or scrub to explore. reset to play again.';
    play();
  } catch (error) { busy = false; $('game-message').textContent = error.message.toLowerCase(); render(); }
});
$('step').addEventListener('click', () => { pause(); step(); });
$('rewind').addEventListener('click', () => { pause(); seek(0); });
$('progress').addEventListener('input', () => { pause(); seek(Number($('progress').value)); });
$('close-rule').addEventListener('click', () => $('rule-dialog').close());
$('puzzle').addEventListener('change', loadPuzzle);
$('reset').addEventListener('click', () => { clearTrace(); values = [...original]; $('game-message').textContent = 'puzzle reset. select a square to play.'; render(); });
$('check').addEventListener('click', () => {
  $('game-message').textContent = conflicts().some(Boolean) ? 'there are conflicting digits. check the highlighted cells.' : values.every(Boolean) ? 'solved! every row, column, and box contains 1–9.' : 'no direct conflicts so far. the board is not complete yet.';
  render();
});
async function initialize() {
  busy = true; values = Array(81).fill(0); original = [...values]; render();
  try {
    const response = await fetch('/api/puzzles'); if (!response.ok) throw new Error('could not load puzzles.');
    fixtures = await response.json(); busy = false; loadPuzzle();
  } catch (error) { $('game-message').textContent = `${error.message.toLowerCase()} start the python server, then reload this page.`; }
}
initialize();
