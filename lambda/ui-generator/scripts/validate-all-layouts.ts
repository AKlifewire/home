import * as fs from 'fs';
import * as path from 'path';
import { validateLayout } from '../utils/validateLayout';

const LAYOUTS_DIR = path.join(__dirname, '../generated-layouts');

if (!fs.existsSync(LAYOUTS_DIR)) {
  console.error('No generated layouts found. Run generate:layouts first.');
  process.exit(1);
}

const layoutFiles = fs.readdirSync(LAYOUTS_DIR)
  .filter(file => file.endsWith('-layout.json'));

console.log(`Found ${layoutFiles.length} layout files to validate`);

let valid = 0;
let invalid = 0;

for (const file of layoutFiles) {
  try {
    console.log(`\nValidating ${file}...`);
    
    const layoutPath = path.join(LAYOUTS_DIR, file);
    const layout = JSON.parse(fs.readFileSync(layoutPath, 'utf8'));
    
    validateLayout(layout);
    
    console.log(`✓ ${file} is valid`);
    valid++;
  } catch (error) {
    console.error(`✗ ${file} is invalid:`, error);
    invalid++;
  }
}

console.log(`\nValidation Summary:`);
console.log(`✓ ${valid} valid layouts`);
console.log(`✗ ${invalid} invalid layouts`);

if (invalid > 0) {
  process.exit(1);
}
