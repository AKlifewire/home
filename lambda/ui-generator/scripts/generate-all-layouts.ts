import * as fs from 'fs';
import * as path from 'path';
import { convertDeviceToUI } from '../device-to-ui-layout';
import { validateLayout } from '../utils/validateLayout';

const MOCKS_DIR = path.join(__dirname, '../mocks');
const OUTPUT_DIR = path.join(__dirname, '../generated-layouts');

// Create output directory if it doesn't exist
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR);
}

// Process all mock configs
const mockFiles = fs.readdirSync(MOCKS_DIR)
  .filter(file => file.endsWith('.json'));

console.log(`Found ${mockFiles.length} mock configurations`);

let succeeded = 0;
let failed = 0;

for (const file of mockFiles) {
  try {
    console.log(`\nProcessing ${file}...`);
    
    // Read mock config
    const configPath = path.join(MOCKS_DIR, file);
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    
    // Generate layout
    const layout = convertDeviceToUI(config);
    
    // Skip if layout is null
    if (!layout) {
      console.log(`⚠ No layout generated for ${file}`);
      failed++;
      continue;
    }
    
    // Validate layout
    validateLayout(layout);
    
    // Save generated layout
    const outputPath = path.join(OUTPUT_DIR, file.replace('.json', '-layout.json'));
    fs.writeFileSync(outputPath, JSON.stringify(layout, null, 2));
    
    console.log(`✓ Successfully generated layout: ${outputPath}`);
    succeeded++;
  } catch (error) {
    console.error(`✗ Failed to process ${file}:`, error);
    failed++;
  }
}

console.log(`\nSummary:`);
console.log(`✓ ${succeeded} configurations processed successfully`);
console.log(`✗ ${failed} configurations failed`);

if (failed > 0) {
  process.exit(1);
}