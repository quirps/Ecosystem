const fs = require('fs');
const solc = require('solc');
const { merge } = require('sol-merger');

async function getASTFromSolidity(contractPath) {
    const source  = await merge(contractPath);
    const input = {
        language: 'Solidity',
        sources: {
            [contractPath]: {
                content: source
            }
        },
        settings: {
            outputSelection: {
                '*': {
                    '*': ['*'],
                }
            }
        }
    };
    
    const compiled = solc.compile(JSON.stringify(input));
    const output = JSON.parse(compiled);
    
    return output.sources[contractPath].ast;
}

function extractFunctionContext(ast, functionName) {
    const extracted = [];
    const functionCalls = [];

    // Recursive function to traverse the AST and extract relevant nodes
    function traverseNode(node) {
        if (node.nodeType === 'FunctionDefinition' && node.name === functionName) {
            extracted.push(node);
            
            // Identify function calls from within the target function
            node.body && node.body.statements && node.body.statements.forEach(statement => {
                if (statement.nodeType === 'ExpressionStatement' && statement.expression.nodeType === 'FunctionCall') {
                    functionCalls.push(statement.expression.expression.name);
                }
            });
        }
        
        // Extract called functions
        if (node.nodeType === 'FunctionDefinition' && functionCalls.includes(node.name)) {
            extracted.push(node);
        }

        // Extract constants
        if (node.nodeType === 'VariableDeclaration' && node.constant) {
            extracted.push(node);
        }

        for (let childKey in node) {
            if (node[childKey] && typeof node[childKey] === 'object') {
                traverseNode(node[childKey]);
            }
        }
    }
    
    traverseNode(ast);
    return extracted;
}

const ast = getASTFromSolidity('/home/joe/Documents/EcoSystem1/contracts/facets/MockERC20.sol');
const context = extractFunctionContext(ast, 'transfer');
console.log(context);