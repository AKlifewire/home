import { generateEnergyMeterLayout } from './energy-meter-generator';
import * as fs from 'fs';
import * as path from 'path';
import { DeviceConfig } from './types';

async function testEnergyMeterUi() {
  try {
    // Load test device configuration
    const configPath = path.join(__dirname, 'examples', 'energy-meter-config.json');
    const deviceConfig: DeviceConfig = JSON.parse(fs.readFileSync(configPath, 'utf-8'));

    console.log('Generating UI layout for device:', deviceConfig.deviceId);
    
    // Generate the UI layout
    const layout = await generateEnergyMeterLayout(deviceConfig);
    
    // Save the generated layout
    const outputPath = path.join(__dirname, 'examples', 'energy-meter-layout.json');
    fs.writeFileSync(outputPath, JSON.stringify(layout, null, 2));
    
    console.log('Generated UI layout saved to:', outputPath);
    console.log('Layout preview:', JSON.stringify(layout, null, 2));
    
    return layout;
  } catch (error) {
    console.error('Error generating UI layout:', error);
    throw error;
  }
}

// Run the test if this file is executed directly
if (require.main === module) {
  testEnergyMeterUi().catch(console.error);
}
