import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { deployNetwork } from './deployNetwork';

export async function quickDeploy(
  hre: HardhatRuntimeEnvironment,
  contractChainId: number
) {
  const parameters = getDeploymentParameters(contractChainId);

  await deployNetwork(
    hre,
    contractChainId,
    parameters.feeTokenAddress,
    0,
    parameters.axelarGatewayAddress,
    parameters.axelarGasServiceAddress,
    parameters.axelarChainName,
    0
  );
}

interface DeploymentParameters {
  feeTokenAddress: string;
  axelarGatewayAddress: string;
  axelarGasServiceAddress: string;
  axelarChainName: string;
}

function getDeploymentParameters(
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

  throw 'Unsupported';
}
