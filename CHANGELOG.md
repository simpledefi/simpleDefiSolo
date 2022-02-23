v0.75.2
- Proxy factory pool initialization requires pool type
    - 0 is for solo farming, and 1 is for pooled farming
    function getContractType(string memory _name, uint _type) external returns (string memory _contract);
