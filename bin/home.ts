#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';

// Import from cdk/app.ts instead of defining stacks here
import '../cdk/app';

// This file is kept for compatibility but actual app definition is in cdk/app.ts