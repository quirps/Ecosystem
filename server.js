// server.js
const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');
const { glob } = require('glob'); // Import glob
const hre = require('hardhat')
const { exec } = require('child_process');

const app = express();
const port = process.env.PORT || 3010; // Use environment variable or default

// --- Configuration ---
const serverArtifactsDir = path.join(__dirname, 'server-artifacts');
const consolidatedArtifactFile = path.join(serverArtifactsDir, 'deployment-artifacts.json');
const typechainFactoriesDir = path.join(__dirname, "./types/ethers-contracts")
// --- Configuration ---
// Adjust this path to point to your actual typechain output directory
// Assuming server.js is in the root of your Hardhat project:
const typechainBaseDir = path.join(__dirname, 'typechain-types');
const ARTIFACTS_DIR = path.join( __dirname, "artifacts")
const consolidatedArtifactFileName = "./server-artifacts/deployment-artifacts.json"
const consolidatedArtifactBasePath = "./server-artifacts/deployment-artifacts"
// Fallback if 'factories' subdirectory doesn't exist
const typechainFallbackDir = typechainBaseDir;
// ---
// --- End Configuration ---


// --- Middleware ---
app.use(cors()); // Enable Cross-Origin Resource Sharing for all origins
app.use(express.json()); // Parse JSON bodies (useful for potential future POST routes)
// Basic logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});
// --- End Middleware ---


// --- Routes ---

app.get('/api/v1/deployment-state', async (req, res) => {
    const rootPath = process.cwd(); // Assumes server is started from project root 
    const {versionNumber} = req.query
    const stateFilePath = path.join(rootPath, consolidatedArtifactBasePath + "-" + `${versionNumber}.json`);
    console.log(`[Server] Request received for ${consolidatedArtifactBasePath}`); // Server-side log
  
    try {
      // Asynchronously read the file content
      const fileContent = await fs.readFile(stateFilePath, 'utf8');
      console.log(`[Server] Successfully read ${stateFilePath}`);
  
      // Parse the JSON content
      try {
        const deploymentState = JSON.parse(fileContent);
        console.log(`[Server] Successfully parsed JSON. Sending response.`);
        // Send the parsed JSON object
        res.status(200).json(deploymentState);
      } catch (parseError) {
        console.error(`[Server] Error parsing JSON from ${stateFilePath}:`, parseError);
        res.status(500).json({ error: 'Failed to parse deployment state file.', details: parseError.message });
      }
    } catch (readError) {
      // Handle file reading errors (e.g., file not found)
      if (readError.code === 'ENOENT') {
        console.warn(`[Server] Deployment state file not found at ${stateFilePath}`);
        res.status(404).json({ error: `Deployment state file not found: ${consolidatedArtifactFileName}` });
      } else {
        console.error(`[Server] Error reading deployment state file ${stateFilePath}:`, readError);
        res.status(500).json({ error: 'Failed to read deployment state file.', details: readError.message });
      }
    }
  });
// Root endpoint
app.get('/', (req, res) => {
  res.status(200).send('Web3 Artifact Server is running!');
});

// Endpoint to serve the consolidated deployment artifacts JSON
app.get('/artifacts', async (req, res) => {
  const versionNumber = req.query.version; // Get version from query parameter

  if (!versionNumber) {
    return res.status(400).json({ error: 'VERSION_NUMBER query parameter is required.' });
  }

  // Construct the full path to the specific version's artifact file
  const consolidatedArtifactFile = `${consolidatedArtifactBasePath}-${versionNumber}.json`;

  try {
    // 1. Check if file exists and is accessible
    await fs.access(consolidatedArtifactFile); // Throws error if not accessible/found

    // 2. If access succeeds, send the file
    // Use path.resolve to ensure absolute path for res.sendFile
    res.sendFile(path.resolve(consolidatedArtifactFile), (err) => {
      if (err) {
        console.error(`Error sending file ${consolidatedArtifactFile}:`, err);
        // Avoid sending another response if headers already sent
        if (!res.headersSent) {
          res.status(500).json({ error: 'Failed to send artifact file.' });
        }
      } else {
        console.log(`Sent artifact file: ${consolidatedArtifactFile}`);
      }
    });

  } catch (error) {
    // Handle errors (file not found, permissions etc.)
    if (error.code === 'ENOENT') { // ENOENT = Error NO ENTity (File not found)
      console.error(`Artifact file not found: ${consolidatedArtifactFile}`);
      res.status(404).json({ error: `Deployment artifacts for version ${versionNumber} not found. Run deployment first.` });
    } else {
      console.error(`Error accessing artifact file ${consolidatedArtifactFile}:`, error);
      res.status(500).json({ error: 'Could not access deployment artifacts.' });
    }
  }
});

// --- Routes ---
app.post('/selectedArtifacts', async (req, res) => { 
  const { filenames } = req.body;

  // --- Input Validation ---
  if (!filenames) {
      return res.status(400).json({ error: 'Missing "filenames" field in request body.' });
  }
  if (!Array.isArray(filenames)) {
      return res.status(400).json({ error: '"filenames" must be an array of strings.' });
  }
  if (!filenames.every(name => typeof name === 'string')) {
       return res.status(400).json({ error: '"filenames" array must contain only strings.' });
  }
  if (filenames.length === 0) {
      return res.status(200).json({}); // Return empty if requested list is empty
  }
  // --- End Validation ---


  console.log(`Received request for artifacts: ${filenames.join(', ')}`);
  console.log(`Searching in base directory: ${ARTIFACTS_DIR}`);

  const results = {};
  let foundCount = 0;
 
  for (const contractName of filenames) {
      if (!contractName) continue; // Skip empty strings just in case

      const targetFilename = `${contractName}.json`;
      const artifactPath = await findFileRecursive(ARTIFACTS_DIR, targetFilename);

      if (artifactPath) {
          console.log(`Found artifact for ${contractName} at: ${artifactPath}`);
          try {
              const fileContent = await fs.readFile(artifactPath, 'utf-8');
              const artifactJson = JSON.parse(fileContent);
              results[contractName] = artifactJson;
              foundCount++;
          } catch (error) {
              console.error(`Error reading or parsing artifact ${artifactPath} for ${contractName}:`, error.message);
              // Decide if you want to signal this error to the client,
              // For now, we just log it and don't include it in the results.
          }
      } else {
          console.warn(`Artifact not found for contract: ${contractName}`);
      }
  }

  console.log(`Found ${foundCount} out of ${filenames.length} requested artifacts.`);
  res.status(200).json(results);
});

async function findFileRecursive(directoryPath, targetFilename) {
  try {
      // Check if directory exists before reading
      if ( await !fs.access(directoryPath) || !(await  fs.stat(directoryPath) ).isDirectory() ) {
          return null;
      }

      const entries = await fs.readdir(directoryPath, { withFileTypes: true });

      for (const entry of entries) {
          const fullPath = path.join(directoryPath, entry.name);

          if (entry.isDirectory()) {
              const foundInSubdir = await findFileRecursive(fullPath, targetFilename);
              if (foundInSubdir) {
                  return foundInSubdir; // Found in subdirectory
              }
          } else if (entry.isFile() && entry.name === targetFilename) {
              return fullPath; // Found the file
          }
      }
  } catch (error) {
      // Log errors like permission denied, but don't crash the search
      console.error(`Error accessing directory ${directoryPath}: ${error.message}`);
  }

  return null; // Not found in this directory or its subdirectories
}

app.get('/version', async (req, res) => {
    // Use path.join for robust path construction
    const ecosystemArtifactPath = path.join(__dirname, 'artifacts', 'hardhat-diamond-abi', 'HardhatDiamondABI.sol', 'Ecosystem.json');
    // Assume consolidatedArtifactFile is also defined using path.join/resolve

    const resource = { ecosystemABI: null, diamondBytecode: null }; // Use null for clarity

    try {
        // 1. Check access and read Ecosystem ABI artifact
        await fs.access(ecosystemArtifactPath);
        const ecoAbiBuffer = await fs.readFile(ecosystemArtifactPath);
        const ecoArtifact = JSON.parse(ecoAbiBuffer.toString('utf-8')); // Parse the JSON

        if (!ecoArtifact || !Array.isArray(ecoArtifact.abi)) {
             console.error(`Invalid or missing ABI array in ${ecosystemArtifactPath}`);
             // Don't proceed if ABI is missing/invalid
             return res.status(500).json({ error: 'Ecosystem artifact is invalid or missing the ABI array.' });
        }
         resource.ecosystemABI = ecoArtifact.abi; // Assign the ABI array

        // 2. Check access and read Consolidated Artifact for Diamond bytecode
        const bytecode = await getDiamondBytecodeIdiomatic();
        if (bytecode) {
            // Use the bytecode...
            console.log("Diamond Bytecode:", bytecode.substring(0, 66) + "..."); // Print snippet
            resource.diamondBytecode = bytecode;
            // If you were in an Express handler context like before:
             return res.status(200).json(resource);
        } else {
            console.log("Failed to retrieve Diamond bytecode.");
            // If you were in an Express handler context:
             return res.status(404).json({ error: "Failed to retrieve Diamond bytecode." });
        }

    } catch (ecoAbiError) {
        // Handle errors specific to the Ecosystem ABI artifact file
        if (ecoAbiError.code === 'ENOENT') {
            console.error(`Ecosystem artifact file not found: ${ecosystemArtifactPath}`);
            return res.status(404).json({ error: 'Ecosystem artifact file not found.' });
        } else {
            console.error(`Error accessing ecosystem artifact ${ecosystemArtifactPath}:`, ecoAbiError);
            return res.status(500).json({ error: 'Error accessing Ecosystem artifact.' });
        }
    }
});

async function getDiamondBytecodeIdiomatic() {
  try {
      // 1. Use hre.artifacts.readArtifact() to get the artifact object
      //    Provide the *Contract Name* (not the file name)
      const diamondArtifact = await hre.artifacts.readArtifact("Diamond");

      // 2. Access the bytecode directly from the artifact object
      const bytecode = diamondArtifact.bytecode;

      // 3. Validate the bytecode (optional but good practice)
      if (typeof bytecode === 'string' && bytecode !== '0x') {
          console.log("Successfully retrieved Diamond bytecode using hre.artifacts.");

          // You can also access the ABI easily:
          // const abi = diamondArtifact.abi;
          // console.log("ABI:", abi);

          return bytecode; // Return the bytecode
      } else {
          console.error("Diamond bytecode is missing, invalid, or empty in the artifact.");
          return null; // Indicate failure
      }

  } catch (error) {
      // hre.artifacts.readArtifact throws an error if the artifact doesn't exist
      console.error("Error reading Diamond artifact:", error.message);
      // Handle cases where the artifact might not be found (e.g., compilation failed, wrong name)
      if (error.message.includes("Artifact for contract \"Diamond\" not found")) {
           console.error("Make sure the 'Diamond' contract is compiled successfully.");
      }
      return null; // Indicate failure
  }
}


// Endpoint to serve specific TypeChain factory files
app.get('/types/factories/:factoryName', async (req, res) => {
    const { factoryName } = req.params;
    // Ensure filename ends with __factory.ts and sanitize
    if (!factoryName || !factoryName.endsWith('__factory.ts')) {
        return res.status(400).json({ error: 'Invalid factory name requested. Must end with __factory.ts' });
    }

    // Basic path traversal prevention (though `path.join` helps)
    if (factoryName.includes('..')) {
        return res.status(400).json({ error: 'Invalid path detected.'});
    }

    const filePath = path.join(typechainFactoriesDir, factoryName);

    if ( await fs.exists(filePath)) {
        res.type('application/typescript'); // Set correct content type
        res.sendFile(filePath);
    } else {
        console.error(`TypeChain factory file not found: ${filePath}`);
        res.status(404).json({ error: `TypeChain factory '${factoryName}' not found.` });
    }
});


// Helper function remains the same
async function getFactoriesDirectory() {
  try {
      await fs.access(typechainFactoriesDir);
      return typechainFactoriesDir;
  } catch (error) {
      try {
          await fs.access(typechainFallbackDir);
          console.warn(`Warning: Using fallback TypeChain directory: ${typechainFallbackDir}. Consider organizing factories under a 'factories' subdirectory.`);
          return typechainFallbackDir;
      } catch (fallbackError) {
           console.error(`Neither primary TypeChain directory (${typechainFactoriesDir}) nor fallback (${typechainFallbackDir}) found.`);
           throw new Error('TypeChain directory not found.');
      }
  }
}


app.get('/types/factories', async (req, res) => {
  let factoryBaseDir;
  try {
      factoryBaseDir = await getFactoriesDirectory();
  } catch (error) {
      console.error(error.message);
      return res.status(404).json({ error: 'TypeChain factories directory configuration error or directory not found.' });
  }

  // --- MODIFIED: Process req.query.files (expecting array or string) ---
  const filesQueryParam = req.body.files; // Could be string[], string, or undefined
  let requestedBasenames = [];
  const specificFilesRequested = filesQueryParam !== undefined;
  // --- End Modification Block ---

  let filePathsToRead = []; // This will store full paths

  try {
      const globPattern = '**/*__factory.ts';
      console.log(`Searching for pattern "${globPattern}" in base directory "${factoryBaseDir}"`);
      const allFactoryPaths = await glob(globPattern, {
          cwd: factoryBaseDir,
          absolute: true,
          nodir: true,
      });

      console.log(`Found ${allFactoryPaths.length} potential factory files via glob.`);
      const factoryMap = new Map(allFactoryPaths.map(p => [path.basename(p), p]));

      if (specificFilesRequested) {
          // --- MODIFIED: Handle specific file requests from array/string ---
          if (Array.isArray(filesQueryParam)) {
              // Multiple files provided (e.g., ?files=a.ts&files=b.ts)
              requestedBasenames = filesQueryParam
                  .map(f => String(f).trim()) // Ensure elements are strings and trim
                  .filter(f => f.endsWith('__factory.ts'));
          } else if (typeof filesQueryParam === 'string') {
               // Single file provided (e.g., ?files=a.ts)
               const trimmedFile = filesQueryParam.trim();
               if (trimmedFile.endsWith('__factory.ts')) {
                   requestedBasenames = [trimmedFile]; // Treat as single-element array
               }
               // We no longer split comma-separated strings here
          }

          if (requestedBasenames.length === 0) {
               // This case means query params were present but invalid or empty after filtering
              return res.status(400).json({ error: 'No valid __factory.ts filenames provided in the query, or format mismatch (expected repeating ?files=... parameter).' });
          }
           console.log(`Processing specific requests for: ${requestedBasenames.join(', ')}`);
          // --- End Modification Block ---

          // --- Existing logic to find paths and check for missing files ---
          const missingFiles = [];
          for (const basename of requestedBasenames) {
              if (factoryMap.has(basename)) {
                  filePathsToRead.push(factoryMap.get(basename));
              } else {
                  missingFiles.push(basename);
              }
          }

          if (missingFiles.length > 0) {
              console.error(`Could not find requested factory files: ${missingFiles.join(', ')}`);
              return res.status(404).json({
                  error: `Could not find all requested factory files. Missing: ${missingFiles.join(', ')}`,
              });
          }
           console.log(`Found full paths for all requested files.`);
          // --- End existing logic block ---

      } else {
          // --- Handle request for all factory files (unchanged) ---
          console.log(`Processing request for all ${allFactoryPaths.length} found factory files.`);
          filePathsToRead = allFactoryPaths;
      }

      // --- Reading file contents logic remains the same ---
      // ... (try reading files in filePathsToRead into factoryContents) ...

      if (filePathsToRead.length === 0) {
           console.log('No factory files match the request.');
           return res.json({});
      }

      const factoryContents = {};
      const errors = [];
      const promises = filePathsToRead.map(async (filePath) => {
           const basename = path.basename(filePath);
           try {
               const content = await fs.readFile(filePath, 'utf-8');
               factoryContents[basename] = content;
           } catch (error) {
                console.error(`Error reading file ${filePath}: ${error.message}`);
                errors.push(`Failed to read file ${basename}: ${error.message}`);
           }
       });

       await Promise.all(promises);

       // Check for critical errors during read
       if (specificFilesRequested) {
          const failedReads = requestedBasenames.filter(basename => !factoryContents.hasOwnProperty(basename));
           if (failedReads.length > 0) {
                console.error(`Failed to read content for specifically requested files: ${failedReads.join(', ')}`);
               return res.status(500).json({
                   error: 'Server error occurred while reading content for some requested files.',
                   details: errors,
                   failedFiles: failedReads
               });
           }
       } else if (errors.length > 0) {
            console.warn(`Encountered ${errors.length} errors while reading all factory files. Returning successfully read data.`);
       }


      console.log(`Successfully prepared content for ${Object.keys(factoryContents).length} factory files.`);
      res.json(factoryContents);

  } catch (error) {
      console.error(`Error processing /types/factories request: ${error.message}`, error.stack);
      res.status(500).json({ error: 'An internal server error occurred.' });
  }
});

// Optional: /list endpoint using glob
app.get('/types/factories/list', async (req, res) => {
   let factoryBaseDir;
  try {
      factoryBaseDir = await getFactoriesDirectory();
      const allFactoryPaths = await glob('**/*__factory.ts', { cwd: factoryBaseDir, nodir: true });
      // Return basenames for the list
      const factoryBasenames = allFactoryPaths.map(p => path.basename(p));
      res.json({ factories: factoryBasenames });
  } catch (error) {
       console.error(`Error listing TypeChain factories: ${error.message}`);
       if(error.message.includes('TypeChain directory not found')) {
           res.status(404).json({ error: error.message });
       } else if (error.code === 'ENOENT'){
            res.status(404).json({ error: 'TypeChain factories directory not found.' });
       }
       else {
          res.status(500).json({ error: 'Could not list TypeChain factories.' });
       }
  }
});



app.get('/devInit', async (req, res) => {
  exec('npx hardhat deploy', (error, stdout, stderr) => {
    if (error) {
      console.error(`Execution error: ${error}`);
      return res.status(500).send(`Error: ${stderr}`);
    }
    console.log(`Output: ${stdout}`);
    res.send(`Deployment done:\n${stdout}`);
  });
});
// --- End Routes ---

app.get('/health', async (req,res)=>{
    res.status(200).send("Web3 Server is running!")
})
// --- Error Handling ---
// Basic 404 handler for undefined routes
app.use((req, res, next) => {
  res.status(404).json({ error: 'Not Found' });
});

// Basic error handler
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err.stack || err);
  res.status(500).json({ error: 'Internal Server Error' });
});
// --- End Error Handling ---


// --- Start Server ---
app.listen(port,'0.0.0.0', () => {
  console.log(`\nArtifact Server listening at http://localhost:${port}`);
  console.log(` -> Serving artifacts from: ${consolidatedArtifactFile}`);
  console.log(` -> Serving TypeChain factories from: ${typechainFactoriesDir}`);
});
// --- End Start Server ---