// SPDX-license_Identifier: MIT

pragma solidity ^0.6.0 < 0.9.0;

contract urlShortener{
    struct urlStruct{
        address owner; // address of person shortening a url
        string url;    // the long complex url to be shortened
        bool exists;   // true if shortened url is present, false otherwise
        bool paid;     // true if the person paid for the transaction, false otherwise
    }

    mapping(bytes => urlStruct) table; // maps the shortened url(bytes) to a urlStruct
    mapping(address => bytes[]) public shortenedUrls; // maps an address to an array of shortened urls(bytes array)

    address[] accounts; // an array to store account address of users who interact with contract
    address payable admin; // the owner of this contract, paid per url shortened

    event notify(string url, bytes slug, address admin); // to be listened by any frontend

    constructor() public{ // initializes admin as the contract creator(has special priviledges)
        admin = msg.sender; // msg.sender holds the address of the person interacting with contract initially 
    }

    // URL SHORTENER LOGIC

    // for person to specify the shortened version of a url
    function shortenUrlWithSlug(string memory _url, bytes memory _short, bool paid) public payable{ // payable - receive ether
        bool initialPaid = false; // default paid - user not yet paid

        if(!table[_short].exists){ // check is shortened url is already in table
            table[_short] = urlStruct(msg.sender, _url, true, paid||initialPaid); // add url to table of mappings
            shortenedUrls[msg.sender].push(_short); // adding the shortened url to the list of urls a person has shortened before

            if(shortenedUrls[msg.sender].length < 1){ // check if it is the first time for a person to shorten an array
                accounts.push(msg.sender); // if so we add him/her to a list of users who interact with this contract
            }

            emit notify(_url, _short, msg.sender); // amit a notification that we can listen on the frontend side
        }
    }

    // generate a short URL
    function getShortSlug(string memory _url) internal pure returns(bytes memory){
        bytes32 hash = sha256(abi.encodePacked(_url)); // hash url using sha hashing algorithm
        uint shiftBy = 15 * 6; // shift bits by
        bytes32 mask = 0xffffff0000000000000000000000000000000000000000000000000000000000; // hex value to act as the mask
        return abi.encodePacked(bytes32(hash << (shiftBy) & mask));
    }

    // shortens url using getShortSlug, here user does not specify the short version of the url
    function shortenUrl(string memory _url, bool _paid) public payable{
        bool initialPaid = false; // user has not yet paid initially
        bytes memory shortenedHash = getShortSlug(_url); // this is the shortened url
        return shortenUrlWithSlug(_url, shortenedHash, _paid||initialPaid); // return the shortened url
    }

    // OTHER FUNCTIONS
    
    // get url from table of mappings
    function getUrl(bytes memory _shortUrl) public view returns(string memory){ // read from the state
        urlStruct storage shortenedUrl = table[_shortUrl];
        if(shortenedUrl.exists){ // check if shortened url exists in table
            return shortenedUrl.url; // if so, return it
        }
        return "NOT IN TABLE"; // otherwise return this text
    }

    // returns a list of accounts from accounts array
    function getAccounts() public view returns(address[] memory){
        return accounts;
    }

    function destroy() public{   // delete a smart contract from the blockchain
        if(msg.sender == admin){ // remaining ether on contract sent to a admin. 
            selfdestruct(admin); // storage and code deleted from blockchain
        }
    }
}
