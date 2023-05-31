export interface Deployment {
  contractChainId: number;
  axelarChainName: string;

  nexusFactoryAddress: string;

  vaultV1ControllerAddress: string;

  publicCatalogAddress: string;
  vaultV1FacetAddress: string;

  nexusGatewayAddress: string;

  links: Link[];
}

export interface Link {
  targetContractChainId: number;
  targetGatewayAddress: string;
}
