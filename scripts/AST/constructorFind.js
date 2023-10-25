const fs = require('fs').promises;
const { execSync } = require('child_process');
const crypto = require('crypto');
const {merge} = require('sol-merger');

const FOLDER_PATH = '/home/joe/Documents/EcoSystem1/contracts/facets';
const ARTIFACTS_PATH = '/home/joe/Documents/EcoSystem1/artifacts';

const removeSolcHeader = (_string) =>{

}
const mergeAndCompileAST = async (sourceFile) => {
    try {
        // Flatten the contract using sol-merger
        const mergedCode = await merge(sourceFile, {removeComments:true});
        // Write the merged code to a temporary file for solc compilation
        const tempFile = `${sourceFile}.temp.sol`;
        await fs.writeFile(tempFile, mergedCode);

        // Compile using solc command line with 'ast-json' option and no comments, remove constant header
        const astOutput = execSync(`solc --ast-compact-json  ${tempFile} `).toString().substr(91);
        
        const astJSON = JSON.parse(astOutput);

        // Clean up the temporary file
        await fs.unlink(tempFile);

        return astJSON.sources[tempFile].AST;
    } catch (error) {
        console.error(`Error processing ${sourceFile}: ${error}`);
        return null;
    }
};

const hasConstructor = (ast) => {
    const nodes = ast.nodes || [];
    return nodes.some(node => node.kind === 'constructor');
};

const getBytecodeHash = (artifactPath) => {
    const artifact = require(artifactPath);
    const bytecode = artifact.evm.bytecode.object;
    return crypto.createHash('keccak256').update(bytecode).digest('hex');
};

(async () => {
    try {
        const files = await fs.readdir(FOLDER_PATH);

        for (const file of files) {
            if (file.endsWith('.sol')) {
                const sourceFile = `${FOLDER_PATH}/${file}`;

                const ast = await mergeAndCompileAST(sourceFile);

                if (ast && hasConstructor(ast)) {
                    const artifactFile = `${ARTIFACTS_PATH}/${file.replace('.sol', '.json')}`;
                    if (await fs.access(artifactFile).then(() => true).catch(() => false)) {
                        const hash = getBytecodeHash(artifactFile);
                        console.log(`File ${file} has a constructor. Keccak256 of its bytecode is: ${hash}`);
                    }
                }
            }
        }
    } catch (err) {
        console.error('Error processing files:', err);
    }
})();
