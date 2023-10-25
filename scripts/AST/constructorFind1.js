const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { merge } = require('sol-merger');

async function getMergedSource(filepath) {
    return await merge(filepath,{removeComments:true});
}

function getAst(mergedSource) {
    const tempFile = 'temp.sol';
    fs.writeFileSync(tempFile, mergedSource);
    const _astOutput = execSync(`solc --ast-compact-json ${tempFile}`,{maxBuffer: 10 * 1024 * 1024 }).toString('utf8');
    const astOutput = _astOutput.substr( _astOutput.indexOf("\n{") + 1)
    fs.unlinkSync(tempFile); // cleanup temp file
    return JSON.parse(astOutput);
}

function getInheritedConstructors(ast) {
    const results = [];
    const contractsWithConstructors = new Set();

    for (let node of ast.nodes) {
        // Check if node is a contract definition
        if (node.nodeType === 'ContractDefinition' && node.nodes.some(childNode => childNode.nodeType === 'FunctionDefinition' && childNode.kind === 'constructor')) {
            contractsWithConstructors.add(node.name);
        }
    }

    for (let node of ast.nodes) {
        if( node.nodeType ==='ContractDefinition' && contractsWithConstructors.has(node.name) && node.nodes.some( (n)=> n.kind =='function' && n.visibility == 'external') ){
            results.push({ inheritedContract: node.name, dependentContract: null })
        }
        if (node.nodeType === 'ContractDefinition' && node.baseContracts.length > 0) {
           
            for (let base of node.baseContracts) {
                if (contractsWithConstructors.has(base.baseName.name)) {
                    results.push({ inheritedContract: base.baseName.name, dependentContract: node.name });
                }
            }
        }
    }

    return results;
}

async function findInheritedContracts(folderPath) {
    const files = fs.readdirSync(folderPath).filter(file => file.endsWith('.sol'));
    const results = [];

    for (let file of files) {
        const fullPath = path.join(folderPath, file);
        const mergedSource = await getMergedSource(fullPath);
        console.log(file)
        if(file == "Members.sol"){
            console.log("")
        }
        const ast = getAst(mergedSource);
        const inheritedConstructors = getInheritedConstructors(ast);
        results.push(...inheritedConstructors);
    }

    return results;
}

const folderPath = '/home/joe/Documents/EcoSystem1/contracts/facets'; // replace with your folder path
findInheritedContracts(folderPath).then(res => {
    console.log(res);
});
