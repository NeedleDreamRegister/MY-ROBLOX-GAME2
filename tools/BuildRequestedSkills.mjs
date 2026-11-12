// Node runner for the requested-skill manifest. Never overwrites a skill.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = fs.readFileSync(path.join(root, 'tools', 'BuildRequestedSkills.py'), 'utf8');
const groups = new Map([...source.matchAll(/^    "([a-z]+)": "([^"]+)",?$/gm)].map(m => [m[1], m[2]]));
const block = source.match(/ROWS = r"""([\s\S]*?)"""/);
if (!block || !groups.size) throw new Error('Skill manifest is missing');
const dest = path.join(root, '.agents', 'skills');
fs.mkdirSync(dest, { recursive: true });
let group, created = 0, skipped = 0;
const seen = new Set();
for (const raw of block[1].split(/\r?\n/)) {
  const line = raw.trim();
  if (!line) continue;
  if (line.endsWith(':')) {
    group = line.slice(0, -1);
    if (!groups.has(group)) throw new Error(`Unknown group: ${group}`);
    continue;
  }
  const parts = line.split('|');
  if (!group || parts.length !== 4) throw new Error(`Bad row: ${line}`);
  const [name, trigger, action, check] = parts;
  if (seen.has(name)) throw new Error(`Duplicate skill: ${name}`);
  seen.add(name);
  const folder = path.join(dest, name);
  if (fs.existsSync(folder)) { skipped++; continue; }
  fs.mkdirSync(folder);
  const description = `Use when ${trigger}. ${action}.`;
  const content = `---\nname: ${name}\ndescription: ${JSON.stringify(description)}\n---\n\n# ${name}\n\n${groups.get(group)}\n\n- Task: ${action}.\n- Check: ${check}.\n- Report the result, evidence, what remains unknown, and the next small step.\n`;
  fs.writeFileSync(path.join(folder, 'SKILL.md'), content);
  created++;
}
console.log(`created=${created} skipped=${skipped} total=${seen.size}`);
