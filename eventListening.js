import { createPublicClient, webSocket } from 'viem'
import { mainnet } from 'viem/chains'

const client = createPublicClient({ 
  chain: mainnet, 
  transport: webSocket('wss://eth-mainnet.g.alchemy.com/v2/YOUR_KEY') 
})

// This "watches" for every Transfer event in real-time
client.watchContractEvent({
  address: '0x...', // The contract you care about
  onLogs: logs => console.log('New event detected!', logs)
})