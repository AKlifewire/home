import { UiLayout, UiScreen, UiWidget } from '../types';
import { DeviceConfig } from '../types/device-config';

export function validateLayout(layout: UiLayout): void {
  // Check version
  if (!layout.version) {
    throw new Error('Layout must have a version');
  }

  // Check metadata
  if (!layout.metadata || !layout.metadata.deviceId) {
    throw new Error('Layout must have metadata with deviceId');
  }

  // Check screens array
  if (!layout.screens || !Array.isArray(layout.screens)) {
    throw new Error('Layout must have a screens array');
  }

  // Validate each screen
  layout.screens.forEach(validateScreen);
}

function validateScreen(screen: UiScreen, index: number): void {
  if (!screen.id) {
    throw new Error(`Screen at index ${index} must have an id`);
  }
  if (!screen.title) {
    throw new Error(`Screen at index ${index} must have a title`);
  }
  if (!screen.widgets || !Array.isArray(screen.widgets)) {
    throw new Error(`Screen at index ${index} must have a widgets array`);
  }

  screen.widgets.forEach((widget, widgetIndex) => validateWidget(widget, screen.id, widgetIndex));
}

function validateWidget(widget: UiWidget, screenId: string, index: number): void {
  if (!widget.type) {
    throw new Error(`Widget at index ${index} in screen ${screenId} must have a type`);
  }
  if (!widget.componentId) {
    throw new Error(`Widget at index ${index} in screen ${screenId} must have a componentId`);
  }
  if (!widget.properties) {
    throw new Error(`Widget at index ${index} in screen ${screenId} must have properties`);
  }

  // Validate widget type
  const validTypes = ['toggle', 'gauge', 'chart', 'video', 'status', 'scheduler', 'header'];
  if (!validTypes.includes(widget.type)) {
    throw new Error(`Widget at index ${index} in screen ${screenId} has invalid type: ${widget.type}`);
  }
}

function validateComponent(component: any, index: number): void {
  // Check required fields
  if (!component.type) {
    throw new Error(`Component at index ${index} must have a type`);
  }
  if (!component.title) {
    throw new Error(`Component at index ${index} must have a title`);
  }

  // Validate type
  const validTypes = ['header', 'gauge', 'switch', 'scheduler', 'status', 'container'];
  if (!validTypes.includes(component.type)) {
    throw new Error(`Component at index ${index} has invalid type: ${component.type}`);
  }

  // Validate nested components
  if (component.components) {
    if (!Array.isArray(component.components)) {
      throw new Error(`Components field at index ${index} must be an array`);
    }
    component.components.forEach((c: any, i: number) => validateComponent(c, i));
  }
}

function validateMeasurements(measurements: Record<string, any>) {
  if (!measurements || typeof measurements !== 'object') {
    throw new Error('Invalid measurements configuration');
  }

  for (const [key, measurement] of Object.entries(measurements)) {
    if (!measurement || typeof measurement !== 'object') {
      throw new Error(`Invalid measurement configuration for ${key}`);
    }
    if (!measurement.unit || typeof measurement.unit !== 'string') {
      throw new Error(`Missing or invalid unit for measurement ${key}`);
    }
    if (measurement.ranges) {
      const ranges = measurement.ranges;
      if (typeof ranges.min !== 'number' || typeof ranges.max !== 'number' ||
          typeof ranges.warning !== 'number' || typeof ranges.critical !== 'number') {
        throw new Error(`Invalid ranges configuration for measurement ${key}`);
      }
      if (ranges.min >= ranges.max) {
        throw new Error(`Invalid range values for measurement ${key}: min must be less than max`);
      }
      if (ranges.warning <= ranges.min || ranges.warning >= ranges.max) {
        throw new Error(`Invalid warning threshold for measurement ${key}`);
      }
      if (ranges.critical <= ranges.warning || ranges.critical >= ranges.max) {
        throw new Error(`Invalid critical threshold for measurement ${key}`);
      }
    }
  }
}