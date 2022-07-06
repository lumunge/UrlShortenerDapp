// SPDX-license_Identifier: MIT

pragma solidity ^0.6.0 < 0.9.0;

contract urlShortener{
    struct urlStruct{
        address admin; // address of person shortening a url
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
    
    // generate a short URL using SHA256 hashig algorithm
    function hashUrl(string memory _url) internal pure returns(bytes memory){
        bytes32 hash = sha256(abi.encodePacked(_url)); // hash url using sha hashing algorithm
        uint shiftBy = 15; // shift bits by
        bytes32 mask = 0xffffff0000000000000000000000000000000000000000000000000000000000; // hex value to act as the mask
        return abi.encodePacked(bytes3(hash << (shiftBy * 6) & mask));
    }

    // shortens url and maps it to user
    function shortenUrl(string memory _url, bool _paid) public payable{
        bool initialPaid = false; // user has not yet paid initially
        bytes memory shortenedHash = hashUrl(_url); // this is the shortened url

        if(!table[shortenedHash].exists){ // check is shortened url is already in table
            table[shortenedHash] = urlStruct(msg.sender, _url, true, _paid||initialPaid); // add url to table of mappings
            shortenedUrls[msg.sender].push(shortenedHash); // adding the shortened url to the list of urls a person has shortened before

            if(shortenedUrls[msg.sender].length <= 1){ // check if it is the first time for a person to shorten an array
                accounts.push(msg.sender); // if so we add him/her to a list of users who interact with this contract
            }

            emit notify(_url, shortenedHash, msg.sender); // amit a notification that we can listen on the frontend side
        }

        // return shortenUrlWithSlug(_url, shortenedHash, _paid||initialPaid); // return the shortened url
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
