pragma solidity 0.4.17;

import "./Reserve.sol";
import {TestToken} from "./TestToken.sol";

contract Exchange {
    
    address public owner;
    address public constant ETH_ADDRESS = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    address public constant DEFAULT_ADDRESS = 0x0000000000000000000000000000000000000000;
    mapping(address => address) public listReserve; 
    uint private constant inWei = 10 ** 18;
    
    function Exchange() public {
        owner = msg.sender;
    }
    
    function addReserve(address _reserve, address _token, bool _isAdd) public returns(bool){
        if(_isAdd) {
            // Reserve reserve = Reserve(_reserve);
            // if (reserve.supportToken() != _token){
            //     return false;
            // }
            listReserve[_token] = _reserve;
            return true;
        }else {
            delete listReserve[_token];
            return true;
        }
        
    }
    
    function getExchangeRate(address _srcToken, address _destToken, uint _srcAmmount) public view returns(uint){
        //if _srcToken = ETH => buy token
        if(_srcToken == ETH_ADDRESS){
            Reserve re = Reserve(listReserve[_destToken]);
            return re.getExchangeRate(true, _srcAmmount);
        }
        //else if _destToken = ETH => sell token
        else if ( _destToken == ETH_ADDRESS){
            re = Reserve(listReserve[_srcToken]);
            return re.getExchangeRate(false, _srcAmmount);
        }
        //else exchange token to token
        else {
            Reserve reSrc = Reserve(listReserve[_srcToken]);
            uint weiRecieved = reSrc.getExchangeRate(false, _srcAmmount);
            Reserve reDest = Reserve(listReserve[_destToken]);
            return reDest.getExchangeRate(true, weiRecieved);
        }
    }

    function() public payable {
    }
    
    function exchangeToken(address _srcToken, address _destToken, uint _srcAmmount) public payable{
        
        TestToken srcTokenContract;
        TestToken destTokenContract;
        Reserve srcReserve;
        Reserve destReserve;
        uint weiRecieved;
        uint tokenReceived;
        
        uint tokenDecimal;
        uint amountInDecimal;
          //if _srcToken = ETH => buy token
          
        if(_srcToken == ETH_ADDRESS){
            
            require(_srcAmmount == msg.value);
            destTokenContract = TestToken(_destToken);
            destReserve = Reserve(listReserve[_destToken]);
            destReserve.exchange.value(msg.value)(true, _srcAmmount);
            tokenReceived = getExchangeRate(ETH_ADDRESS, _destToken, _srcAmmount);
            destTokenContract.transfer(msg.sender, tokenReceived);
            
        } else if ( _destToken == ETH_ADDRESS){ //else if _destToken = ETH => sell token
        
            srcTokenContract = TestToken(_srcToken);
            srcReserve = Reserve(listReserve[_srcToken]);
            
            tokenDecimal = srcTokenContract.decimals();
            amountInDecimal = _srcAmmount * 10 ** tokenDecimal;

            srcTokenContract.transferFrom(msg.sender, address(this), amountInDecimal);
            srcTokenContract.approve(address(srcReserve), amountInDecimal);

            srcReserve.exchange(false, _srcAmmount);
            weiRecieved = getExchangeRate(_srcToken, ETH_ADDRESS, _srcAmmount);
            (msg.sender).transfer(weiRecieved);
            
        }else { //else exchange token to token
            //sell token
            srcTokenContract = TestToken(_srcToken);
            srcReserve = Reserve(listReserve[_srcToken]);
            // uint approvedAllowence = srcTokenContract.allowance(msg.sender, this);
            // require(approvedAllowence ==  _srcAmmount);

            tokenDecimal = srcTokenContract.decimals();
            amountInDecimal = _srcAmmount * 10 ** tokenDecimal;

            srcTokenContract.transferFrom(msg.sender, this, amountInDecimal);//  transfer directly to reserve contract
            srcTokenContract.approve(address(srcReserve), amountInDecimal);
            srcReserve.exchange(false, _srcAmmount);
            weiRecieved = getExchangeRate(_srcToken, ETH_ADDRESS, _srcAmmount);
            
            //buy token
            destTokenContract = TestToken(_destToken);
            destReserve = Reserve(listReserve[_destToken]);

            destReserve.exchange.value(weiRecieved)(true, weiRecieved);
            tokenReceived = getExchangeRate(ETH_ADDRESS, _destToken, weiRecieved);
            destTokenContract.transfer(msg.sender, tokenReceived);
            
        }
    }
    
}
