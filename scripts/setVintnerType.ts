import { ethers } from 'hardhat'
import { vintnerAddress } from './address'
import { BigNumber } from 'ethers'
import fs from 'fs'

interface IParams {
  tokenId: number
  vintnerType: number
}

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const vintnerContract = await ethers.getContractAt(
    'Vintner',
    vintnerAddress,
    deployer,
  )
  const vintnerTypeList: IParams[] = require('./vintnertype.json')
  // console.log('vintnerTypeList', vintnerTypeList)
  for (const element of vintnerTypeList) {
    // vintnerTypeList.forEach(async (element: IParams) => {
    if (element.tokenId >= 306 && element.tokenId <= 4000) {
      console.log('element', element)
      const tx = await vintnerContract.setVintnerType(
        BigNumber.from(element.tokenId),
        BigNumber.from(element.vintnerType),
      )
      await tx.wait()
    }
  }

  return ''
}

// Command
// npx hardhat run --network avaxmainnet scripts/setVintnerType.ts

main()
  .then((r: string) => {
    return r
  })
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
