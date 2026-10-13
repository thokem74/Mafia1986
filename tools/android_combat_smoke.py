"""Exercise a saved debug fight through real Android touch controls, not state edits.

Requires the game in combat at 2340x1080, with inline hints enabled. Preserves RNG;
uses the same simple shot/path strategy as the opponent. Logs only game state.
"""
import collections
import json
import subprocess
import time

ADB = '/home/thokem/Android/Sdk/platform-tools/adb'
DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]
TOUCHES = [ (1963, 525), (2194, 525), (2079, 428), (2079, 626)]
WALLS = [(18, 3), (20, 15), (18, 9)]
RANGES = [2, 2, 2, 2, 15, 15, 20, 20, 15]

def adb(*args):
    return subprocess.check_output([ADB, *args], text=True)

def campaign():
    return json.loads(adb('shell', 'run-as', 'org.thokem.mafia1986', 'cat', 'files/autosave.json'))['campaign']

def blocked(cell, units, ignored):
    x, y = cell
    if not (1 <= x <= 37 and 1 <= y <= 17):
        return True
    if any(abs(x-wx) < 2 and abs(y-wy) < 2 for wx, wy in WALLS):
        return True
    return any(i != ignored and u['energy'] > 0 and abs(x-u['x']) < 2 and abs(y-u['y']) < 2 for i, u in enumerate(units))

def target(units, index, direction, origin):
    shooter = units[index]
    dx, dy = direction
    x, y = origin
    if direction == (1, 0):
        x += 1
        y += 1
    elif direction in [(-1, 0), (0, 1)]:
        y += 1
    for _ in range(RANGES[shooter['weapon']]):
        x += dx
        y += dy
        if not (0 < x < 39 and 0 < y < 19):
            return False
        if any(wx <= x < wx+2 and wy <= y < wy+2 for wx, wy in WALLS):
            return False
        for i, unit in enumerate(units):
            if i != index and unit['side'] != shooter['side'] and unit['energy'] > 0 and unit['x'] <= x < unit['x']+2 and unit['y'] <= y < unit['y']+2:
                return True
    return False

def choose(combat):
    units = combat['units']
    index = combat['active']
    origin = units[index]['x'], units[index]['y']
    for direction in DIRECTIONS:
        if target(units, index, direction, origin):
            return 'attack', direction
    queue = collections.deque([origin])
    first = {origin: None}
    while queue:
        cell = queue.popleft()
        if cell != origin and any(target(units, index, direction, cell) for direction in DIRECTIONS):
            return 'move', first[cell]
        for direction in DIRECTIONS:
            neighbor = cell[0]+direction[0], cell[1]+direction[1]
            if neighbor not in first and not blocked(neighbor, units, index):
                first[neighbor] = first[cell] or direction
                queue.append(neighbor)
    return 'skip', None

if __name__ == '__main__':
    start = time.monotonic()
    actions = 0
    for iteration in range(4000):
        state = campaign()
        combat = state['combat']
        if not combat:
            print('ANDROID FIGHT COMPLETE', state['objectives'], 'actions', actions, 'seconds', round(time.monotonic()-start), flush=True)
            break
        if combat['units'][combat['active']]['side'] == 1:
            time.sleep(.15)
            continue
        mode, direction = choose(combat)
        if mode == 'skip':
            adb('shell', 'input', 'tap', '2079', '823')
        else:
            adb('shell', 'input', 'tap', '2199' if mode == 'attack' else '1963', '726')
            time.sleep(.05)
            x, y = TOUCHES[DIRECTIONS.index(direction)]
            adb('shell', 'input', 'tap', str(x), str(y))
        actions += 1
        if actions % 20 == 0:
            print('ANDROID ACTION', actions, combat['reason'], 'round', combat['round'], flush=True)
        time.sleep(.1)
    else:
        raise SystemExit('Android fight did not terminate')
