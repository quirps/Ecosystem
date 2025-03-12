import ethers from 'ethers'
import ecosystemDeploy from "./ecosystemDeploy"

export async function minimalDeploy(){
  const signers  = await ethers.getSigners()

   const ecosystemConfig = {
    name : "Test",
    version : "1.0.0",
    owner : signers[0]
   }
  await ecosystemDeploy()
}


