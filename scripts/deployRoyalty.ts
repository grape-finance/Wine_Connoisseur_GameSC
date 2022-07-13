import { ethers } from 'hardhat'
import { WAVAXAddress } from './address'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const Royalties = await ethers.getContractFactory('Royalties')
  const Royalties_Deployed = await Royalties.deploy(WAVAXAddress)

  return Royalties_Deployed.address
}

main()
  .then((r: string) => {
    console.log('deployed address:', r)
    return r
  })
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
