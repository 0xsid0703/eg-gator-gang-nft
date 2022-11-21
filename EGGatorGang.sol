// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/*
*  ________           __                      ________                          
* /  _____/ _____   _/  |_   ____  _______   /  _____/ _____     ____     ____  
* /   \  ___ \__  \  \   __\ /  _ \ \_  __ \ /   \  ___ \__  \   /    \   / ___\ 
* \    \_\  \ / __ \_ |  |  (  <_> ) |  | \/ \    \_\  \ / __ \_|   |  \ / /_/  >
*  \______  /(____  / |__|   \____/  |__|     \______  /(____  /|___|  / \___  / 
*        \/      \/                                 \/      \/      \/ /_____/  
*/

contract GatorGang is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    // token counter
    Counters.Counter private _tokenIds;

    // NFT Name
    string public constant TOKEN_NAME = "Gator Gang";
    // NFT Symbol
    string public constant TOKEN_SYMBOL = "GG";

    // total NFT number
    uint256 public maxTotalSupply;

    // total NFTs minted in presale
    uint256 public totalMintNumberPresale;

    // total NFTs minted in public sale
    uint256 public totalMintNumberPublicSale;

    // total NFTs airdropped
    uint256 public totalMintNumberAirDrop;

    // presale limit
    uint256 public presaleLimit;
    // public sale max number
    uint256 public publicSaleLimit;

    // presale price
    uint256 public presalePrice;
    // public sale price
    uint256 public publicSalePrice;

    // Presale requires presaleStatus true
    bool public presaleStatus;
    /**
     *  Public Sale requries publicSaleStatus TRUE
     *  Public Sale requries this variable to be TRUE
     */
    bool public publicSaleStatus;

    // NFT toke `baseURI`
    string public baseURI;

    // mapping address to flag of White Listed Address
    mapping(address => bool) private _whiteList;

    // mapping nft number to flag of sold
    mapping(uint256 => bool) private _nftSoldList;

    // mapping address to White Listed token number
    mapping(address => uint256) private _whitelistSold;

    // total currency in this contract
    uint256 private _totalCurrency;

    /**
     *  Emitted when `_tokenBaseURI` updated
     */
    event BaseURI(string bseURI);

    /**
     *  Emitted when `publicSaleStatus` updated
     */
    event PublicSaleStatus(bool status);

    /**
     *  Emitted when `presaleStatus` updated
     */
    event PresaleStatus(bool status);

    /**
     *  Emitted when `presaleLimit` updated
     */
    event PresaleLimit(uint256 counter);

    /**
     *  Emitted when `publicSaleLimit` updated
     */
    event PublicSaleLimit(uint256 counter);

    /**
     *  Emitted when `presalePrice` updated
     */
    event PresalePrice(uint256 price);

    /**
     *  Emitted when `publicSalePrice` updated
     */
    event PublicSalePrice(uint256 price);

    /**
     *  Emitted when client added to `_whiteList`
     */
    event ClientAddedToWhiteList(address[] clients);

    /**
     *  Emitted when client removed from `_whiteList`
     */
    event ClientRemovedFromWhiteList(address[] clients);

    /**
     *  Emitted when token sold in presale
     */
    event Presale(address indexed client, uint256 amount, uint256 price);

    /**
     *  Emitted when token sold in public sale
     */
    event PublicSale(address indexed client, uint256 amount, uint256 price);

    /**
     *  Emitted when Airdrop
     */
    event Airdrop(address indexed client, uint256[] tokensIds);

    /**
     *  Emitted when Withdraw
     */
    event Withdraw(address indexed owner, address indexed to, uint256 amount);

    // https://eg-nft-api-dev.herokuapp.com/api/v1/nft/
    constructor(string memory BASEURI) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
        baseURI = BASEURI;
        maxTotalSupply = 8888;
        totalMintNumberPresale = 0;
        totalMintNumberPublicSale = 0;
        totalMintNumberAirDrop = 0;
        _totalCurrency = 0;
        presaleLimit = 5;
        publicSaleLimit = 20;
        presalePrice = 60_000_000_000_000_000; // 0.06
        publicSalePrice = 160_000_000_000_000_000; // 0.16
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     *  set `baseURI`
     */
    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
        emit BaseURI(uri);
    }

    /**
     *  set `presaleLimit`
     */
    function setPresaleLimit(uint256 counter) external onlyOwner {
        require(counter > 0, "GatorGang: Presale amount limit can't be zero.");
        if (presaleLimit != counter) {
            presaleLimit = counter;
        }
        emit PresaleLimit(counter);
    }

    /**
     *  set `publicSaleLimit`
     */
    function setPublicSaleLimit(uint256 counter) external onlyOwner {
        require(counter > 0, "GatorGang: Public sale amount limit can't be zero.");
        if (publicSaleLimit != counter) {
            publicSaleLimit = counter;
        }
        emit PublicSaleLimit(counter);
    }

    /**
     *  set `presalePrice`
     */
    function setPresalePrice(uint256 price) external onlyOwner {
        require(price > 0, "GatorGang: Presale amount can't be zero.");
        if (presalePrice != price) {
            presalePrice = price;
        }
        emit PresalePrice(price);
    }

    /**
     *  set `publicSalePrice`
     */
    function setPublicSalePrice(uint256 price) external onlyOwner {
        require(price > 0, "GatorGang: Public sale amount can't be zero.");
        if (publicSalePrice != price) {
            publicSalePrice = price;
        }
        emit PublicSalePrice(price);
    }

    /**
     *  set `publicSaleStatus`
     */
    function setPublicSaleStatus(bool status) external onlyOwner {
        if (publicSaleStatus != status) {
            publicSaleStatus = status;
        }
        emit PublicSaleStatus(status);
    }

    /**
     *  set `presaleStatus`
     */
    function setPresaleStatus(bool status) external onlyOwner {
        if (presaleStatus != status) {
            presaleStatus = status;
        }
        emit PresaleStatus(status);
    }

    /**
     *  @param clients list array for white list
     *  insert clients into WhiteList
     *  set true for `_whiteList[clients[i]]`
     */
    function addClientToWhiteList(address[] calldata clients)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < clients.length; i++) {
            require(
                clients[i] != address(0),
                "GatorGang: Zero address can't be added to the whitelist."
            );
        }
        for (uint256 i = 0; i < clients.length; i++) {
            if (_whiteList[clients[i]] != true) {
                _whiteList[clients[i]] = true;
            }
        }
        emit ClientAddedToWhiteList(clients);
    }

    /**
     *  @param clients is address to be removed from whitelist
     *  remove clients from WhiteList
     *  set false for `_whiteList[clients[i]]`
     */
    function removeClientFromWhiteList(address[] calldata clients)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < clients.length; i++) {
            if (_whiteList[clients[i]] == true) {
                _whiteList[clients[i]] = false;
            }
        }
        emit ClientRemovedFromWhiteList(clients);
    }

    /**
     *  @param client address
     *  @return true when client is in the white list
     */
    function isClientInWhiteList(address client) public view returns (bool) {
        return _whiteList[client];
    }

    function presaleMint(uint256 amount) internal {
        require(
            _whiteList[msg.sender] == true,
            "GatorGang: You are not added to the whitelist."
        );
        require(
            presalePrice * amount == msg.value,
            "GatorGang: Your presale payment amount does not match required presale minting amount."
        );
        require(
            (amount + _whitelistSold[msg.sender]) <= presaleLimit,
            "GatorGang: Your presale payment amount exceeds our presale minting amount limit."
        );
        for (uint256 i = 0; i < amount; i++) {
            while (_nftSoldList[_tokenIds.current()] == true) {
                _tokenIds.increment();
            }
            _nftSoldList[_tokenIds.current()] = true;
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
        _totalCurrency += presalePrice * amount;
        totalMintNumberPresale += amount;
        _whitelistSold[msg.sender] += amount;
        emit Presale(msg.sender, amount, msg.value);
    }

    function publicSaleMint(uint256 amount) internal {
        require(publicSaleStatus == true, "GatorGang: Public sale is not live.");
        require(
            publicSalePrice * amount == msg.value,
            "GatorGang: Your public sale payment amount does not match required presale minting amount."
        );
        require(
            amount <= publicSaleLimit,
            "GatorGang: Your presale payment amount exceeds our presale minting amount limit."
        );
        for (uint256 i = 0; i < amount; i++) {
            while (_nftSoldList[_tokenIds.current()] == true) {
                _tokenIds.increment();
            }
            _nftSoldList[_tokenIds.current()] = true;
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
        _totalCurrency += publicSalePrice * amount;
        totalMintNumberPublicSale += amount;
        emit PublicSale(msg.sender, amount, msg.value);
    }

    /**
     *  @param amount is amount for minting
     *  access by admin
     */
    function clientMint(uint256 amount) external payable {
        require(amount > 0, "GatorGang: Mint amount can't be zero");
        require(
            (getTotalMintNumber() + amount) <= maxTotalSupply,
            "GatorGang: You can't mint that amount of tokens. Exceeds max supply."
        );

        if (presaleStatus == true) {
            presaleMint(amount);
        } else {
            publicSaleMint(amount);
        }
    }

    /**
     *  @param client airdrop address
     *  @param tokenIdArray token number address for airdrop
     * access by admin
     */
    function adminAirdrop(address client, uint256[] calldata tokenIdArray)
        external
        onlyOwner
    {   
        require(client != address(0), "GatorGang: You can't airdrop to the zero address");
        for (uint256 i = 0; i < tokenIdArray.length; i++) {
            require(
                tokenIdArray[i] < maxTotalSupply,
                "GatorGang: You can't airdrop that amount of tokens. Exceeds max supply."
            );
            require(
                _nftSoldList[tokenIdArray[i]] == false,
                "GatorGang: You can't airdrop token already minted."
            );
        }
        for (uint256 i = 0; i < tokenIdArray.length; i++) {
            _nftSoldList[tokenIdArray[i]] = true;
            _safeMint(client, tokenIdArray[i]);
        }
        totalMintNumberAirDrop += tokenIdArray.length;
        emit Airdrop(client, tokenIdArray);
    }

    /**
     * get total funds accumulated in this smart contract 
     * access admin
     */
    function getTotalCurrency() external view onlyOwner returns (uint256) {
        return _totalCurrency;
    }

    /**
     * get total mint number
     */
    function getTotalMintNumber() public view returns (uint256) {
        return
            totalMintNumberAirDrop +
            totalMintNumberPresale +
            totalMintNumberPublicSale;
    }

    /**
     * @param to is wallet address that receives accumulated funds
     * @param value transer amount
     * access admin
     */
    function withdrawAdmin(address payable to, uint256 value)
        external
        onlyOwner
    {
        require(to != address(0), "GatorGang: Can't withdraw to the zero address.");
        require(
            value <= address(this).balance,
            "GatorGang: Withdraw amount exceed the balance of this contract."
        );
        to.transfer(value);
        emit Withdraw(owner(), to, value);
    }
}
