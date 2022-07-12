import { ethers } from 'hardhat'
import { vintnerAddress } from './address'
import { BigNumber } from 'ethers'

interface IParams {
  tokenId: BigNumber
  vintnerType: BigNumber
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
  const array: IParams[] = makeRandomArray()
  for (const item of array) {
    try {
      console.log('item', item)
      await vintnerContract.setVintnerType(item.tokenId, item.vintnerType)
    } catch (error) {
      console.log(`Error getting the data $ {error}`)
    }
  }
  return ''
}

const makeRandomArray = (): IParams[] => {
  let array: IParams[] = []

  for (let i = 71; i < 70; i++) {
    let randomNumber = Math.floor(Math.random() * 100) // 1 ~ 100
    randomNumber = randomNumber < 95 ? 1 : 2
    array.push({
      tokenId: BigNumber.from(i + 1),
      vintnerType: BigNumber.from(randomNumber),
    })
  }
  return array
}

main()
  .then((r: string) => {
    return r
  })
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
