#!/usr/bin/env node

const { program } = require('commander');
const fs = require('fs');
const path = require('path');

program
  .option('-f, --file <path>', 'JSON file path')
  .action((options) => {
    const { file } = options;
    
    if (!file) {
      console.error('Please specify a JSON file path with the -f option.');
      process.exit(1);
    }

    // Resolve the path relative to the current working directory
    const filePath = path.resolve(process.cwd(), file);

    if (!fs.existsSync(filePath)) {
      console.error(`File not found at ${filePath}`);
      process.exit(1);
    }

    fs.readFile(filePath, 'utf8', (err, data) => {
      if (err) {
        console.error(`Error reading the file: ${err}`);
        process.exit(1);
      }
      
      let jsonData;
      try {
        jsonData = JSON.parse(data);
      } catch (e) {
        console.error(`Error parsing JSON: ${e}`);
        process.exit(1);
      }

      console.log('JSON data:', jsonData);
    });
    //deploy with configs
  });

program.parse(process.argv);
/**
 * Two CLI's One for blockchain development
 * Other for off-chain related proccess
 * This can be done as only one is exposed to w
 * 
 * Blockchain
 * - Contract/Integrated Testing
 * - Facet Related Creations
 * Off-Chain
 * - Prisma schema
 * - GraphQL Schema
 * - DeployEnvironmentTests
 */
