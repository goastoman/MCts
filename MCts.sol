pragma solidity ^0.4.21;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract StandartToken is Ownable {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint dec = 10**decimals;

    //uint256 DEC = 10 ** uint256(decimals);
    address public owner;
    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint public buyPrice = 800000000000000;

    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function StandartToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply;
        balanceOf[this] = totalSupply;
        avaliableSupply = balanceOf[this];
        name = tokenName;
        symbol = tokenSymbol;
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function burn(uint256 _value) internal onlyOwner returns (bool success) {
        totalSupply -= _value;
        avaliableSupply -= _value;
        emit Burn(this, _value);
        return true;
    }
}

/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
contract MainSale is StandartToken{

    // группа var с адресами бенефициаров
    address public multisig = 0x253579153746cD2D09C89e73810E369ac6F16115;
    address public escrow = 0x2Ab1dF22ef514ab94518862082E653457A5c1aFc;
    address founders = 0x33648E28d3745218b78108016B9a138ab1e6dA2C;
    address reserve = 0xD4B65C7759460aaDB4CE4735db8037976CB115bb;
    address bounty = 0x7d5874aDD89B0755510730dDedb5f3Ce6929d8B2;

    address[] public _whitelist = [
    0x253579153746cD2D09C89e73810E369ac6F16115, 0x2Ab1dF22ef514ab94518862082E653457A5c1aFc,
    0x33648E28d3745218b78108016B9a138ab1e6dA2C, 0xD4B65C7759460aaDB4CE4735db8037976CB115bb,
    0x7d5874aDD89B0755510730dDedb5f3Ce6929d8B2, 0x0B529De38cF76901451E540A6fEE68Dd1bc2b4B3]; // массив адресов вайтлиста

    uint256 public membersWhiteList;
    mapping(address=>bool) public whitelist; // топ 1/3
    mapping(address=>bool) public waitlist; // топ 2/3
    uint256 public membersWaitlist;

    address[] public _waitlist = [0xB820e7Fc5Df201EDe64Af765f51fBC4BAD17eb1F, 0x81Cfe8eFdb6c7B7218DDd5F6bda3AA4cd1554Fd2,
    0xC032D3fCA001b73e8cC3be0B75772329395caA49]; // массив адресов вайтлиста


    // группа var с количеством токенов для бенефициаров
    uint constant foundersReserve = 23000000000000000000000000;
    uint constant reserveFund = 5000000000000000000000000;
    uint constant bountyReserve = 2000000000000000000000000;

    // var для сейла
    uint64 public startIco = 1521538006;
    uint64 public saleForAll = 1521610814; // старт + 18 дней
    uint64 public endIco = 1531699200;
    uint public weisRaised;
    uint public hardCap = 50000000000000000000000; // 30,000,000 USD ~ 50,000 ether
    uint public softCap = 10000000000000000000000; // 10,000 Ether ~ 5,000,000 USD
    uint public bonusSum;
    bool public isFinalized = false;
    bool public mintingFinished = false;
    //bool public periodWL;

    mapping(address => uint256) balances;

    // эвенты
    event Finalized();
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    // модификатор прокерки можно ли выпускать токены
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    // модификатор достижения сбора средств
    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }

    //функция старта ICO
    function MainSale() public StandartToken(100000000000000000000000000, "Noize-MC", "MC"){
        addWhiteList();
        addWaitlist();
        distributionTokens();
    }

    // функция добавления адресов в вайтлист
    function addWhiteList() public onlyOwner {
        for (uint i=0; i<_whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
            membersWhiteList =_whitelist.length;
        }
    }

    function addWaitlist() public onlyOwner {
        for (uint i=0; i<_waitlist.length; i++) {
            waitlist[_waitlist[i]] = true;
            membersWaitlist =_waitlist.length;
        }
    }

    // функция проверки на наличие в вайтлисте
    function isWhitelisted(address who) public view returns(bool) {
        return whitelist[who];
    }
    // функция проверки на наличие в вейтлисте
    function isWaitlisted(address who) public view returns(bool) {
        return waitlist[who];
    }


    // функция добавления новых участников в Whitelist
    function addMembersWhite(address who) public onlyOwner {
        if (isWhitelisted(who)) {
            revert();
        } else {
            _whitelist.push(who);
            delete waitlist[who];

        }
    }
    // функция добавления новых участников в waitlist
    function addMembersWait(address who) public onlyOwner {
        if (isWhitelisted(who) && isWaitlisted(who)) {
            revert();
        } else {
            _waitlist.push(who);
        }
    }

    // внутренняя функция рассылки токенов бенефициарам
    function distributionTokens() internal {
        _transfer(this, bounty, bountyReserve);
        _transfer(this, founders, foundersReserve);
        _transfer(this, reserve, reserveFund);
        avaliableSupply -= 30000000000000000000000000;
    }




    //изменение даты начала ICO
    function setStartIco(uint64 newStartIco) public onlyOwner {
        startIco = newStartIco;
    }

    //изменение даты окончания ICO
    function setEndIco(uint64 newEndIco) public onlyOwner{
        endIco = newEndIco;
    }

    //изменение даты окончания сейла для WL
    function setSaleForAllEndIco(uint64 newsaleForAll) public onlyOwner{
        saleForAll = newsaleForAll;
    }

    // изменение цены токена
    function setPrices(uint newPrice) public onlyOwner {
        buyPrice = newPrice;
    }

    // изменение hardCap
    function setHardCap(uint newhardCap) public onlyOwner {
        hardCap = newhardCap;
    }

    // изменение softCap
    function setSoftCap(uint newsoftCap) public onlyOwner {
        softCap = newsoftCap;
    }





    // функция приема средств
    function () isUnderHardCap public payable {
        //require(now > startIco && now < endIco);
        if(!isWhitelisted(msg.sender) && now>startIco && now <= saleForAll) {
            revert();
        } else if(!isWaitlisted(msg.sender) && now > startIco && now <= saleForAll) {
            revert();
        } else {
            bonusSum = msg.value;
            discountDate(msg.sender, msg.value);
            discountSum(msg.sender, msg.value);
            weisRaised = weisRaised.add(msg.value);
            multisig.transfer(msg.value);
        }
    }


    // функция доп токенов по дате вложения
    function discountDate(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(dec).div(buyPrice); // добавили пересчет эфира в 18 нулей


        //25% для топ 1/3
        if (isWhitelisted(msg.sender) && now > startIco && now < saleForAll ) { //1-18 days
            _amount = _amount.add(withDiscount(_amount, 25));
        }

        // 20% для чуваков из 2/3 топа
        else if (isWaitlisted(msg.sender) && now > startIco && now < saleForAll) {//1-18 days
            _amount = _amount.add(withDiscount(_amount, 20));

            // all proved 15%
        } else if (now > saleForAll && now < saleForAll + 1555200) { // 19-36 days
            _amount = _amount.add(withDiscount(_amount, 15));
            // all proved 10%
        } else if (now > saleForAll + 1555200 && now < saleForAll + 3110400) { // 37 - 54 days
            _amount = _amount.add(withDiscount(_amount, 10));
        } // all proved 5%
        else if (now > saleForAll + 3110400 && now < saleForAll + 4665600) { //55 - 72 days
            _amount = _amount.add(withDiscount(_amount, 5));
        } // 3
        else if  (now > saleForAll + 4665600 && now <endIco) {// 3% 72 - 92 день - проверки на дату не будет(двойная)
            _amount = _amount.add(withDiscount(_amount, 3));
        } else {
            revert();
        }
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }

    //функция доп токенов по сумме  вложения
    function discountSum(address _investor, uint256 amount) internal {
        uint256 _amount = amount.mul(dec).div(buyPrice);

        // больше 640
        if (bonusSum > 640 ) { //  10%  350к ~ 200 ether
            _amount = withDiscount(_amount, 10);

            // 150 - 350 7%, 272-640 ether
        } else if (bonusSum > 272  && bonusSum < 640 ) {
            _amount = withDiscount(_amount, 7);

            // 50 - 150 5%, 90-272 ether
        } else if (bonusSum > 90  && bonusSum < 272 ) {
            _amount = withDiscount(_amount, 5);

            // 10 - 50 3%, 20 - 90 ether
        } else if (bonusSum > 20  && bonusSum < 90 ) {
            _amount = withDiscount(_amount, 3);

        } else {
            _amount = withDiscount(_amount, 0);
        }
        avaliableSupply -= _amount;
        _transfer(this, _investor, _amount);
    }

    // функция высчитывания доп токенов
    function withDiscount(uint256 _amount, uint _percent) internal pure returns (uint256) {
        return ((_amount * _percent) / 100);
    }

    // завершение контракта
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(now > endIco || weisRaised > hardCap);
        isFinalized = true;
        burn(avaliableSupply);
        balanceOf[this] = 0;
    }

    // функция печати дополнительных токенов
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require(now > endIco);
        _amount = _amount.mul(dec);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    //функция вывода эфира с контракта
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        //amount = amount;
        _to.transfer(amount);
    }

    //функция окончания выпуска токенов
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    // функция добавления адреса в whitelist
    function addParticipant(address who) onlyOwner public {
        require(who != owner);
        _whitelist.push(who);
        whitelist[who] = true;
    }
}
