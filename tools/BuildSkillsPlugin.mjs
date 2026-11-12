import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const source = path.join(root, '.agents', 'skills');
const target = path.join(root, 'plugins', 'dig-the-mountain-skills', 'skills');
if (!fs.existsSync(source)) throw new Error(`Missing source: ${source}`);
fs.mkdirSync(target, { recursive: true });
const names = fs.readdirSync(source, { withFileTypes: true }).filter(x => x.isDirectory()).map(x => x.name).sort();
for (const name of names) {
  const skill = path.join(source, name);
  const file = path.join(skill, 'SKILL.md');
  if (!fs.existsSync(file)) throw new Error(`Missing SKILL.md: ${name}`);
  const body = fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n/g, '\n');
  if (!body.startsWith('---\n') || !new RegExp(`^name: ${name}$`, 'm').test(body) || !/^description: /m.test(body)) {
    throw new Error(`Invalid frontmatter: ${name}`);
  }
  fs.cpSync(skill, path.join(target, name), { recursive: true, force: true });
  fs.writeFileSync(path.join(target, name, 'SKILL.md'), body);
}
const packaged = fs.readdirSync(target, { withFileTypes: true }).filter(x => x.isDirectory()).map(x => x.name).sort();
if (packaged.length !== names.length || packaged.some((name, i) => name !== names[i])) {
  throw new Error('Packaged skills do not match source skills');
}
console.log(`Packaged ${names.length} skills`);
