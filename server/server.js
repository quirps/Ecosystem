// server.js
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const port = process.env.PORT || 3010; // Use environment variable or default

// --- Configuration ---
const serverArtifactsDir = path.join(__dirname, 'server-artifacts');
const consolidatedArtifactFile = path.join(serverArtifactsDir, 'deployment-artifacts.json');
const typechainFactoriesDir = path.join(serverArtifactsDir, 'typechain-factories');
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

// Root endpoint
app.get('/', (req, res) => {
  res.send('Web3 Artifact Server is running!');
});

// Endpoint to serve the consolidated deployment artifacts JSON
app.get('/artifacts', (req, res) => {
  if (fs.existsSync(consolidatedArtifactFile)) {
    res.sendFile(consolidatedArtifactFile);
  } else {
    console.error(`Artifact file not found: ${consolidatedArtifactFile}`);
    res.status(404).json({ error: 'Deployment artifacts not found. Run deployment first.' });
  }
});

// Endpoint to serve specific TypeChain factory files
app.get('/types/factories/:factoryName', (req, res) => {
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

    if (fs.existsSync(filePath)) {
        res.type('application/typescript'); // Set correct content type
        res.sendFile(filePath);
    } else {
        console.error(`TypeChain factory file not found: ${filePath}`);
        res.status(404).json({ error: `TypeChain factory '${factoryName}' not found.` });
    }
});

// Optional: Endpoint to list available factory files
app.get('/types/factories', (req, res) => {
    if (fs.existsSync(typechainFactoriesDir)) {
        try {
            const files = fs.readdirSync(typechainFactoriesDir)
                            .filter(file => file.endsWith('__factory.ts'));
            res.json({ factories: files });
        } catch (error) {
            console.error(`Error reading TypeChain factories directory: ${error}`);
            res.status(500).json({ error: 'Could not list TypeChain factories.' });
        }
    } else {
        console.error(`TypeChain factories directory not found: ${typechainFactoriesDir}`);
        res.status(404).json({ error: 'TypeChain factories directory not found.' });
    }
});

// --- End Routes ---


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
app.listen(port, () => {
  console.log(`\nArtifact Server listening at http://localhost:${port}`);
  console.log(` -> Serving artifacts from: ${consolidatedArtifactFile}`);
  console.log(` -> Serving TypeChain factories from: ${typechainFactoriesDir}`);
});
// --- End Start Server ---