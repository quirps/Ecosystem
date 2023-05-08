const fs = require('fs')

/**
 * json - 
 *      mainVersion : "1.2..."
 *      optimizations: {
 *                          maxTicket : {
 *                                         paramTypes : [uint256[]]
 *                                           }
 *                      }
 * util function takes name of optimization with param types and 
 * creates signature
 */

/**
 * This program should run  a switch where each case is a member 
 */

function expressionGenerator(ids: number[]): string {
    let switchStatementArray: string[] = []
    let switchStatement: string ;
    //is limited ticket type temp variable
    switchStatementArray.push("bool isTicketLimitedId;")
    //begin assembly
    switchStatementArray.push("assembly{ switch a ")
    for (let id of ids) {
        switchStatementArray.push(` case ${id} {
                                        isTicketLimited := true;
                                     }
                                `)
    }
    //end assembly
    switchStatementArray.push('}')

    //function call
    switchStatementArray.push('ticketLimitCheck(id, amount);')
    switchStatement = switchStatementArray.join("")
    return switchStatement
}


console.log( expressionGenerator([1,2,3,4,5]) )