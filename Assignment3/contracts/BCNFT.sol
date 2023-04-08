// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BCNFT is ERC721Enumerable, Ownable {
    using Address for address;

    constructor() ERC721("BCNFT", "BC") {}

    uint mintablecost = 1 ether;
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

    //지갑주소에 해당하는 유저의 정보를 저장
    mapping(address => UserProfile) private _userProfiles;

    // 지갑에 할당된 민팅권환의 개수를 저장하는 매핑
    mapping(address => uint) private _mintableOf;

    //ERC721 tokenId에 맞게 유저정보(명함)를 저장하는 array
    UserProfile[] private _BusinessCards;

    //register와 userUpdate를 구분하는 이유는 최초민팅권환 10회를 제공하기 위함입니다.

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
        require(
            bytes(_userProfiles[user].name).length == 0,
            "You already registered"
        );
        _userProfiles[user] = UserProfile(
            _name,
            _company,
            _position,
            _phoneNum
        );
        unchecked {
            _mintableOf[user] += free_supply;
        }
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
        require(
            bytes(_userProfiles[user].name).length > 0,
            "You need to register first"
        );
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
        unchecked {
            _mintableOf[sender] -= amount;
        }

        for (uint i = 0; i < amount; i++) {
            //여기서 질문이 이렇게 해도 이후에 userprofile을 수정해도 _BusinessCards에는 영향이 없는건가요?
            //_BusinessCard에 푸시되는 값이 struct자체인건지 아니면 _userProfiles[sender]의 주소인건지 궁금합니다.
            _BusinessCards.push(_userProfiles[sender]);
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
}
