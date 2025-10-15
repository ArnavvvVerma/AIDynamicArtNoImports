// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title On-Chain AI Art NFTs (single-file, no imports, no constructor, mint() has no inputs)
/// @notice Minimal ERC-721 compatible implementation with dynamic on-chain metadata (SVG embedded in base64 JSON)
contract AIDynamicArtNoImports {
    // --- ERC-721 basic state ---
    string public name = "AI Dynamic Art";
    string public symbol = "AIDA";

    // token owner mapping and balances
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;

    // approvals
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // auto-increment token id counter
    uint256 private _currentTokenId;

    // events (ERC-721)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- ERC-165 / interface support (minimal) ---
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        // ERC165: 0x01ffc9a7
        // ERC721: 0x80ac58cd
        // ERC721Metadata: 0x5b5e139f
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f;
    }

    // --- ERC-721 core read functions ---
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "nonexistent token");
        return owner;
    }

    // approvals
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "not owner nor operator");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // transfers
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(), "unsafe recipient");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(), "unsafe recipient");
    }

    // --- internal helpers ---
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "mint to zero");
        require(!_exists(tokenId), "already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "not owner");
        require(to != address(0), "transfer to zero");

        // clear approval
        _tokenApprovals[tokenId] = address(0);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // minimal recipient check (for demo). Real contracts should perform ERC721Receiver checks.
    function _checkOnERC721Received() private pure returns (bool) {
        return true;
    }

    // --- PUBLIC mint with NO INPUT FIELDS ---
    /// @notice Mint a new token. No inputs required. Token is assigned to msg.sender.
    function mint() external {
        _currentTokenId += 1;
        uint256 newId = _currentTokenId;
        _mint(msg.sender, newId);
    }

    // --- DYNAMIC METADATA (on-chain JSON + SVG) ---
    /// @notice Returns data:application/json;base64,<base64(json)> metadata. JSON has image: data:image/svg+xml;base64,<...>
    /// Metadata is dynamic because it uses recent block values (timestamp, previous blockhash), creating evolving art.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "nonexistent token");

        // derive pseudo-random seeds from tokenId and chain state (dynamic)
        bytes32 seedA = keccak256(abi.encodePacked(tokenId, block.timestamp, blockhash(block.number > 0 ? block.number - 1 : 0)));
        bytes32 seedB = keccak256(abi.encodePacked(seedA, block.coinbase, block.difficulty));

        uint256 circles = 3 + (uint256(seedA) % 5); // 3..7
        uint256 rects = 1 + (uint256(seedB) % 4);   // 1..4

        string memory color1 = _hexColor(uint256(seedA));
        string memory color2 = _hexColor(uint256(seedB));
        string memory color3 = _hexColor(uint256(seedA ^ seedB));

        string memory svg = _buildSVG(tokenId, circles, rects, color1, color2, color3);

        string memory image = string(abi.encodePacked("data:image/svg+xml;base64,", _base64(bytes(svg))));

        string memory json = string(
            abi.encodePacked(
                '{"name":"AI Dynamic #',
                _toString(tokenId),
                '","description":"AI-generated dynamic on-chain art. Appearance may change as chain data evolves.","image":"',
                image,
                '","attributes":[{"trait_type":"circles","value":',
                _toString(circles),
                '},{"trait_type":"rects","value":',
                _toString(rects),
                '},{"trait_type":"palette","value":"',
                color1,
                "|",
                color2,
                "|",
                color3,
                '"}]}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", _base64(bytes(json))));
    }

    // --- SVG builder ---
    function _buildSVG(
        uint256 tokenId,
        uint256 circles,
        uint256 rects,
        string memory c1,
        string memory c2,
        string memory c3
    ) internal pure returns (string memory) {
        string memory header = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">',
                '<rect width="100%" height="100%" fill="#0b0b0b"/>'
            )
        );

        string memory body = "";
        // concentric-ish circles with pseudo-variation based on tokenId and loop index
        for (uint256 i = 0; i < circles; i++) {
            uint256 r = 60 + ((tokenId * (i + 7)) % 420); // radius 60..479
            uint256 cx = 412 + (uint256(keccak256(abi.encodePacked(tokenId, i))) % 200); // 412..611
            uint256 cy = 412 + (uint256(keccak256(abi.encodePacked(i, tokenId))) % 200); // 412..611
            string memory col = (i % 3 == 0) ? c1 : (i % 3 == 1) ? c2 : c3;
            uint256 sw = 6 + (i % 10);
            body = string(
                abi.encodePacked(
                    body,
                    '<circle cx="',
                    _toString(cx),
                    '" cy="',
                    _toString(cy),
                    '" r="',
                    _toString(r),
                    '" fill="none" stroke="',
                    col,
                    '" stroke-width="',
                    _toString(sw),
                    '" opacity="0.85"/>'
                )
            );
        }

        // rectangles layered with low opacity
        for (uint256 j = 0; j < rects; j++) {
            uint256 x = (tokenId * (j + 3)) % 700; // 0..699
            uint256 y = (tokenId * (j + 11)) % 700; // 0..699
            uint256 w = 120 + (j * 70);
            uint256 h = 80 + (j * 60);
            string memory colr = (j % 2 == 0) ? c2 : c3;
            body = string(
                abi.encodePacked(
                    body,
                    '<rect x="',
                    _toString(x),
                    '" y="',
                    _toString(y),
                    '" width="',
                    _toString(w),
                    '" height="',
                    _toString(h),
                    '" rx="12" ry="12" fill="',
                    colr,
                    '" opacity="0.16"/>'
                )
            );
        }

        string memory footer = "</svg>";
        return string(abi.encodePacked(header, body, footer));
    }

    // --- color helper (produce #rrggbb from uint seed) ---
    function _hexColor(uint256 seed) internal pure returns (string memory) {
        bytes memory tbl = "0123456789abcdef";
        bytes memory out = new bytes(7);
        out[0] = "#";
        for (uint256 i = 0; i < 6; i++) {
            uint256 nib = (seed >> (i * 4)) & 0xF;
            out[1 + i] = tbl[nib];
        }
        return string(out);
    }

    // --- minimal uint -> string ---
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- BASE64 encoder (internal, standard alphabet) ---
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function _base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        bytes memory result = new bytes(encodedLen + 32);

        assembly {
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            let modLen := mod(mload(data), 3)
            switch modLen
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d) // '='
                mstore8(sub(resultPtr, 2), 0x3d) // '='
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d) // '='
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
