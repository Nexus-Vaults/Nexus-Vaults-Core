import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployNetwork } from './deployNetwork';

export async function quickDeploy(
  hre: HardhatRuntimeEnvironment,
  testnet: boolean,
  contractChainId: number
) {
  const parameters = testnet
    ? getDeploymentParametersTestnet(contractChainId)
    : getDeploymentParametersMainnet(contractChainId);

  await deployNetwork(hre, {
    contractChainId: contractChainId,
    nexusCreationFeeAmount: 0,
    vaultV1FacetFeeAmount: 0,
    isTestnet: testnet,
    ...parameters,
  });
}

interface DeploymentParameters {
  feeTokenAddress: string;
  axelarGatewayAddress: string;
  axelarGasServiceAddress: string;
  axelarChainName: string;
}

function getDeploymentParametersTestnet(
  contractChainId: number
): DeploymentParameters {
  if (contractChainId == 1) {
    return {
      feeTokenAddress: '0xf1277d1ed8ad466beddf92ef448a132661956621',
      axelarGatewayAddress: '0x97837985Ec0494E7b9C71f5D3f9250188477ae14',
      axelarGasServiceAddress:
        '0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6',
      axelarChainName: 'Fantom',
    };
  }
  if (contractChainId == 2) {
    return {
      feeTokenAddress: '0x9c3c9283d3e44854697cd22d3faa240cfb032889',
      axelarGatewayAddress: '0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B',
      axelarGasServiceAddress:
        '0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6',
      axelarChainName: 'Polygon',
    };
  }
  if (contractChainId == 3) {
    return {
      feeTokenAddress: '0x272061e3076d100896cddd5f9437b9f55a8cc091',
      axelarGatewayAddress: '0x5769D84DD62a6fD969856c75c7D321b84d455929',
      axelarGasServiceAddress:
        '0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6',
      axelarChainName: 'Moonbeam',
    };
  }

  throw 'Unsupported';
}

function getDeploymentParametersMainnet(contractChainId: number) {
  if (contractChainId == 1) {
    return {
      feeTokenAddress: '0x04068da6c83afcfa0e13ba15a6696662335d5b75',
      axelarGatewayAddress: '0x304acf330bbE08d1e512eefaa92F6a57871fD895',
      axelarGasServiceAddress:
        '0x2d5d7d31F671F86C782533cc367F14109a082712',
      axelarChainName: 'Fantom',
    };
  }
  if (contractChainId == 2) {
    return {
      feeTokenAddress: '0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
      axelarGatewayAddress: '0x6f015F16De9fC8791b234eF68D486d2bF203FBA8',
      axelarGasServiceAddress:
        '0x2d5d7d31F671F86C782533cc367F14109a082712',
      axelarChainName: 'Polygon',
    };
  }
  if (contractChainId == 3) {
    return {
      feeTokenAddress: '0xca01a1d0993565291051daff390892518acfad3a',
      axelarGatewayAddress: '0x4F4495243837681061C4743b74B3eEdf548D56A5',
      axelarGasServiceAddress:
        '0x2d5d7d31F671F86C782533cc367F14109a082712',
      axelarChainName: 'Moonbeam',
    };
  }

  throw 'Unsupported';
}
