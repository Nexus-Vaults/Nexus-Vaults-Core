//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Diamond} from '../diamond/Diamond.sol';
import {INexus} from './INexus.sol';

contract Nexus is Diamond, INexus {}
