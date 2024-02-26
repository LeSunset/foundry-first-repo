// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();
error FundMe_InsufficientETHSent(uint256 minimumUSD);
error FundMe_WithDrawFailed();

contract FundMe{
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    uint256 public constant MINIMUM_USD = 5e18;
    
    address private immutable i_owner;
    AggregatorV3Interface private immutable i_PriceFeed;
    
    constructor(address _PriceFeed) {
        i_owner = msg.sender;
        i_PriceFeed = AggregatorV3Interface(_PriceFeed);
    }

    function fund() public payable {
        if(msg.value.getConversionRate(i_PriceFeed) < MINIMUM_USD){
            revert FundMe_InsufficientETHSent(MINIMUM_USD);
        }
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }
    
    function getVersion() public view returns (uint256){
        return i_PriceFeed.version();
    }
    
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }
    
    function withdraw() public onlyOwner {
        for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(!callSuccess) revert FundMe_WithDrawFailed();
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    // In Ihrem FundMe.sol Vertrag
    function getPublicConversionRate(uint256 ethAmount) public view returns (uint256) {
        return ethAmount.getConversionRate(i_PriceFeed);
    }

    function getPublicPrice() public view returns (uint256) {
        return PriceConverter.getPrice(i_PriceFeed);
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly