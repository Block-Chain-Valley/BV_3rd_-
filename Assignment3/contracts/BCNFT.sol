// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


// 수영: 전체적으로 매우 깔끔합니다ㅎㅎ
// storage 변수 (변수, mapping 등)까리 모아두고, event 선언끼리 모아두고, enum끼리 모아두는게 일반적입니다.
contract BCNFT is ERC721Enumerable, Ownable {
    using Address for address;

    constructor() ERC721("BCNFT", "BC") {}

    uint mintablecost = 1 ether;

    // 수영: 통일성을 위해 freeSupply는 어떨까요?
    uint public free_supply = 10;
    uint public rank0cost = 0.5 ether;
    uint public rank1cost = 0.3 ether;
    uint public rank2cost = 0.1 ether;

    // 개인 관련

    //이름, 소속회사, 직급, 폰번호를 유저의 정보로 저장.
    struct UserProfile {
        string name;
        string company;
        string position;
        string phoneNum;
    }

    // 수영: 이 mapping들을 private로 한 이유가 있나요?
    //지갑주소에 해당하는 유저의 정보를 저장
    mapping(address => UserProfile) private _userProfiles;

    // 지갑에 할당된 민팅권환의 개수를 저장하는 매핑
    mapping(address => uint) private _mintableOf;

    // 등록한 사용자인지 확인하는 매핑
    mapping(address => bool) private _isRegistered;

    //ERC721 tokenId에 맞게 유저정보(명함)를 저장하는 array
    UserProfile[] private _BusinessCards;

    //register와 userUpdate를 구분하는 이유는 최초민팅권환 10회를 제공하기 위함입니다.

    // 수영: phoneNum -> tel 어떨까요ㅋㅋ
    //register 이벤트
    event Register(
        address indexed user,
        string name,
        string company,
        string position,
        string phoneNum
    );

    //user가 자신의 정보를 업데이트 할 때의 event
    event UserUpdate(
        address indexed user,
        string name,
        string company,
        string position,
        string phoneNum
    );

    // 유저가 최초로 register를 하면 유저의 정보를 저장하고 민팅권환 10회를 부여합니다.
    function register(
        string calldata _name,
        string calldata _company,
        string calldata _position,
        string calldata _phoneNum
    ) external {
        address user = _msgSender();
        require(user.isContract(), "You can't register from contract");
        // 수영: require(!_isRegistered[user], ...) 정도로 쓸 수 있을 것 같네요
        require(_isRegistered[user] == false, "You already registered");
        _userProfiles[user] = UserProfile(
            _name,
            _company,
            _position,
            _phoneNum
        );
        unchecked {
            _mintableOf[user] += free_supply;
        }
        _isRegistered[user] = true;
        emit Register(user, _name, _company, _position, _phoneNum);
    }

    // user가 자신의 정보를 업데이트할 때 사용하는 함수입니다.
    function userUpdate(
        string calldata _name,
        string calldata _company,
        string calldata _position,
        string calldata _phoneNum
    ) external {
        address user = _msgSender();
        require(_isRegistered[user] == true, "You need to register first");
        _userProfiles[user] = UserProfile(
            _name,
            _company,
            _position,
            _phoneNum
        );
        emit UserUpdate(user, _name, _company, _position, _phoneNum);
    }

    // 민팅권환을 구매할 때의 event
    event BuyMintable(address indexed user, uint amount);

    //user가 민팅권한을 구매하는 함수입니다.
    function buyMintable(uint amount) external payable {
        require(
            msg.value == mintablecost * amount,
            "You need to send correct amount of Ether"
        );
        address user = _msgSender();

        // 수영: free_supply는 변수로 지정되어있는데, 여기 amount에 곱해지는 수는 10으로 fix되어있는 이유가 있나요?
        // free_supply도 변경 불가능한 constant로 하거나
        // 여기 "10"도 변경 가능한 변수로 지정하면 좋을 것 같네요.
        unchecked {
            _mintableOf[user] += 10 * amount;
        }
        emit BuyMintable(user, 10 * amount);
    }

    event BCMinted(address indexed to, uint256 indexed tokenId);

    //user가 현재 자신의 profile을 기반으로 명함을 to에게 민팅하는 함수입니다.
    function mintBC(address to, uint amount) public {
        address sender = _msgSender();
        require(_mintableOf[sender] >= amount, "Not enough mintable");
        require(
            bytes(_userProfiles[sender].name).length > 0,
            "You need to register first"
        );
        // 수영: GOOD!
        unchecked {
            _mintableOf[sender] -= amount;
        }

        for (uint i = 0; i < amount; i++) {
            //여기서 질문이 이렇게 해도 이후에 userprofile을 수정해도 _BusinessCards에는 영향이 없는건가요?
            //_BusinessCard에 푸시되는 값이 struct자체인건지 아니면 _userProfiles[sender]의 주소인건지 궁금합니다.
            // 수영: struct 자체가 될 것 같네요
            // -> 나중에 유저가 정보를 수정해도 이미 발급된 명함의 정보는 바뀌지 않는 효과가 발생하겠네요
            _BusinessCards.push(_userProfiles[sender]);

            // 수영:
            // storage 변수에 대한 call은 가스 cost가 비싼 편입니다. 
            // 여기서는 `_BusinessCards.length`라는 스토리지 콜을 "amount"번 하고 있네요.
            // for문 밖에서 `uint prevLength = _BusinessCards.length`로 설정해두고,
            // for문 안에서 `uint tokenId = prevLength + i` 이렇게 쓰면 스토리지 콜을 한 번만 해도 돼서
            // 가스를 아낄 수 있을 것 같네요.
            uint tokenId = _BusinessCards.length - 1;
            _safeMint(to, tokenId);
            emit BCMinted(to, tokenId);
        }
    }

    // 조직 관련

    // deposit한 금액에 따라 명함 발행 금액을 다르게 설정하기 위한 enum
    enum Rank {
        rank0,
        rank1,
        rank2
    }

    // 현재 organization이 deposit한 금액
    mapping(address => uint) private _organizationBalance;
    // 지갑주소와 organization의 정보를 매핑.
    mapping(address => OrganizationProfile) private _organizations;
    // 지갑주소와 organization의 등급을 매핑.
    mapping(address => Rank) private _rankOf;
    // organization이 deposit한 금액이 2이상인지 확인하는 modifier
    modifier isOrganization() {
        require(
            _organizationBalance[_msgSender()] > 2 ether,
            "Deposit 2 ether first"
        );
        _;
    }
    // 민팅을 하기전 조직이 자신의 이름을 설정했는지 확인하는 modifier
    modifier isSetName() {
        require(
            bytes(_organizations[_msgSender()].name).length > 0,
            "You need to set name first"
        );
        _;
    }
    
    // organization의 정보를 저장하는 struct
    // 수영: balance와 _rankOf을 profile에 넣지 않은 이유는?
    // 아니면 아예 다 따로 빼서 organizationNameOf를 만들고
    // mapping(address => mapping(address => bool)) isMember 이렇게 분리해도 될듯!
    struct OrganizationProfile {
        string name;
        //해당 지갑주소가 회사의 멤버가 맞는지 확인
        mapping(address => bool) isMember;
    }

    // organization이 deposit한 금액을 확인하는 함수
    function getBalance(address organization) public view returns (uint) {
        return _organizationBalance[organization];
    }

    event Deposit(address indexed sender, uint amount);
    event Withdraw(address indexed sender, uint amount);

    //예치금을 deposit하는 함수
    function deposit() external payable {
        require(msg.value > 0, "You need to send some Ether");
        address sender = _msgSender();
        unchecked {
            _organizationBalance[sender] += msg.value;
        }
        uint organizationBalance = getBalance(sender);

        // 수영: 조직의 rank가 staking한 양에만 의존하는 것이라면,
        // 굳이 rank라는 변수를 따로 관리할 필요가 있을지?
        if (organizationBalance < 3 ether) {
            _rankOf[sender] = Rank.rank0;
        } else if (organizationBalance < 4 ether) {
            _rankOf[sender] = Rank.rank1;
        } else {
            _rankOf[sender] = Rank.rank2;
        }
        emit Deposit(sender, msg.value);
    }

    //예치금을 withdraw하는 함수
    function withdraw(uint amount) external {
        require(_organizationBalance[msg.sender] >= amount, "Not enough funds");
        address sender = _msgSender();
        uint organizationBalance = getBalance(sender);
        unchecked {
            _organizationBalance[sender] = organizationBalance - amount;
        }
        organizationBalance = getBalance(sender);
        if (organizationBalance < 3 ether) {
            _rankOf[sender] = Rank.rank0;
        } else if (organizationBalance < 4 ether) {
            _rankOf[sender] = Rank.rank1;
        } else {
            _rankOf[sender] = Rank.rank2;
        }

        // 수영:
        // https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/TransferHelper.sol
        // 나중에는 위 라이브러리 import 해서 safeTransferETH로 간단하게 써도 좋을 듯!
        (bool sent, bytes memory data) = sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit Withdraw(sender, amount);
    }

    // organization의 name을 설정하는 함수
    function SetNameofOrganization(
        string calldata _name
    ) external isOrganization {
        address organization = _msgSender();
        _organizations[organization].name = _name;
    }

    // organization에 멤버를 등록하는 함수
    function registerMember(address member) external isOrganization {
        address organization = _msgSender();
        _organizations[organization].isMember[member] = true;
    }

    // organization의 rank에 맞게 명함을 민팅할 수 있는 횟수를 구매하는 함수
    function buyOrgMintable(uint amount) public payable isOrganization {
        address organization = _msgSender();
        Rank rank = _rankOf[organization];
        if (rank == Rank.rank0) {
            require(
                msg.value == rank0cost * amount,
                "You need to send correct amount of Ether"
            );
        } else if (rank == Rank.rank1) {
            require(
                msg.value == rank1cost * amount,
                "You need to send correct amount of Ether"
            );
        } else if (rank == Rank.rank2) {
            require(
                msg.value == rank2cost * amount,
                "You need to send correct amount of Ether"
            );
        }
        unchecked {
            _mintableOf[organization] += amount * 10;
        }
        emit BuyMintable(organization, amount * 10);
    }

    //organization이 소속 Member에게 amount만큼의 명함을 민팅해주는 함수
    function MintOrgBC(
        address member,
        uint amount
    ) external payable isOrganization isSetName {
        address organization = _msgSender();
        require(_mintableOf[organization] >= amount, "Not enough mintable");
        require(
            _organizations[organization].isMember[member],
            "Register the member first!"
        );
        unchecked {
            _mintableOf[organization] -= amount;
        }
        for (uint i = 0; i < amount; i++) {
            // 이렇게 하는 것이 맞나요? sturct는 memory 변수로 선언해야 하는 것으로 아는데 위의 질문과 비슷하게 헷갈립니다.
            // 수영: `UserProfile memory user = _userProfiles[member];`
            UserProfile memory user = UserProfile({
                name: _userProfiles[member].name,
                company: _organizations[organization].name,
                position: _userProfiles[member].position,
                phoneNum: _userProfiles[member].phoneNum
            });
            _BusinessCards.push(user);
            uint tokenId = _BusinessCards.length - 1;
            _safeMint(member, tokenId);
            emit BCMinted(member, tokenId);
        }
    }

    //컨트랙트 관리

    receive() external payable {
        revert("You need to send correct function call");
    }

    fallback() external payable {
        revert("You need to send correct function call");
    }

    function setMintableCost(uint _cost) external onlyOwner {
        mintablecost = _cost;
    }

    function setFreeSpply(uint amount) external onlyOwner {
        free_supply = amount;
    }

    function setRank0cost(uint _cost) external onlyOwner {
        rank0cost = _cost;
    }

    function setRank1cost(uint _cost) external onlyOwner {
        rank1cost = _cost;
    }

    function setRank2cost(uint _cost) external onlyOwner {
        rank2cost = _cost;
    }

    // ------------------------------------------------------------
    // 수영: 변수를 이렇게 선언해 보는 건 어떨지?
    // 뭔가 엄청 많아보이지만 다 합치면 uint256이다.
    // -> uint 하나 쓰는 거랑 동일한 효과
    //  자세한 사용법은, 아래의 Slot0 참고!
    // https://github.com/Uniswap/v3-core/blob/d8b1c635c275d2a9450bd6a78f3fa2484fef73eb/contracts/UniswapV3Pool.sol#L56
    struct Costs {
        uint128 baseCost;
        // rank0~2가 mint하는 cost
        // e.g. rank0cost = rank0Multiplier * baseCost
        uint16 rank0Multiplier;
        uint16 rank1Multiplier;
        uint16 rank2Multiplier;

        // rank0~2를 나누는 스테이킹 양의 기준
        // e.g. rank0Stake = rank0StakeMultiplier * baseCost
        uint16 rank0StakeMultiplier;
        uint16 rank1StakeMultiplier;
        uint16 rank2StakeMultiplier;

        // mintableCost = mintMultiplier * baseCost
        uint16 mintMultiplier;

        uint8 freeSupply;
        // buy할 때 나오는 mintable 개수(여기서는 10)
        uint8 bundle;
    }
}
