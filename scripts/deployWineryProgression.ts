import { ethers } from 'hardhat'
import { grapeTokenAddress } from './address'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const WineryProgression = await ethers.getContractFactory('WineryProgression')
  const WineryProgression_Deployed = await WineryProgression.deploy(grapeTokenAddress)

  return WineryProgression_Deployed.address
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
