export interface ChainDeployment {
  contractChainId: number;
  axelarChainName: string;

  deployerAddress: string;

  diamondLoupeFacetAddress?: string | null;
  nexusFactoryAddress?: string | null;
  vaultV1ControllerAddress?: string | null;
  publicCatalogAddress?: string | null;
  vaultV1FacetAddress?: string | null;
  nexusGatewayAddress?: string | null;
  gatewayVaultControllerLinked: boolean;

  links: GatewayLink[];
  facetListings: FacetListing[];
}

export interface GatewayLink {
  targetContractChainId: number;
  targetGatewayAddress: string;
}

export interface FacetListing {
  facetAddress: string;
  feeToken: string;
  feeAmount: number;
}

export interface ChainDeploymentParameters {
  contractChainId: number;
  feeTokenAddress: string;
  nexusCreationFeeAmount: number;
  axelarGatewayAddress: string;
  axelarGasServiceAddress: string;
  axelarChainName: string;
  vaultV1FacetFeeAmount: number;
  isTestnet: boolean;
}
