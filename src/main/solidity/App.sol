pragma ton-solidity >= 0.53.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "https://raw.githubusercontent.com/tonlabs/debots/49eb9ea211c7146ba00895bcbe05b5e76d3c720c/Debot.sol";
import "https://raw.githubusercontent.com/DeShir/everscale-service_discovery/bdd31dc3b0d5c22c95868d2a4afce13d1279e730/src/main/solidity/service/ServiceDiscoveryClient.sol";
import "https://raw.githubusercontent.com/DeShir/everscale-service_discovery/bdd31dc3b0d5c22c95868d2a4afce13d1279e730/src/main/solidity/service/IServiceDiscovery.sol";
import "https://raw.githubusercontent.com/DeShir/everscale-service/8472e40e339e66af81b594d6b66082df8c425c01/src/main/solidity/debot/tezos/ITezosAccountService.sol";
import "./interface/_all.sol";

contract App is Debot, ServiceDiscoveryClient, ITezosAccountServiceCallback {
    optional(string) private accountAddr;
    optional(uint32) private signBoxHandle;

    ITezosAccountServiceMenuItem.MenuItem[] private menuItems;
    address[] private services;

    uint private callbackCounter;

    /// @notice Entry point function for DeBot.
    function start() public override {
        findDebotTezosServices();
    }

    function findDebotTezosServices() private {
        find(["debot", "tezos", "account"]);
    }

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns (
        string name, string version, string publisher, string caption, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Tezos Wallet DeBot 2";
        version = "0.2.0";
        publisher = "ShiroKovka(Oba!=)";
        caption = "";
        author = "ShiroKovka";
        support = address.makeAddrStd(0, 0xfe9a76f1a8584fbd8f092b20e917918969fc8a7b1759e9a8c15a7f907e4d72a5);
        hello = "Hello, I am here to help you with your Tezos Account.";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [Menu.ID, Terminal.ID];
    }

    function findCallback(address[] addrs) public override {
        callbackCounter = addrs.length;

        services = addrs;
        menuItems = new ITezosAccountServiceMenuItem.MenuItem[](0);

        for(address addr : addrs) {
            ITezosAccountServiceMenuItem(addr).menuItem{
                callback: menuItemCallback
            }(TezosLibrary.Account(accountAddr, signBoxHandle));
        }

        if(callbackCounter == 0) {
            showMainMenu();
        }
    }

    function menuItemCallback(ITezosAccountServiceMenuItem.MenuItem menuItem) public {
        callbackCounter -= 1;
        menuItems.push(menuItem);
        if(callbackCounter == 0) {
            showMainMenu();
        }
    }

    function allCallback(IServiceDiscovery.Service[] _services) public override {

    }

    function showMainMenu() private {
        MenuItem[] mainMenuItems;
        for(ITezosAccountServiceMenuItem.MenuItem menuItem : menuItems) {
            mainMenuItems.push(MenuItem(menuItem.title, menuItem.description, tvm.functionId(mainMenuItemCallback)));
        }
        mainMenuItems.push(MenuItem("Update Main Menu", "", tvm.functionId(mainRefreshCallback)));
        Menu.select("Main menu", "", mainMenuItems);
    }

    function mainRefreshCallback(uint32 index) public {
        findDebotTezosServices();
    }

    function mainMenuItemCallback(uint32 index) public {
        ITezosAccountServiceRun(services[index]).run(TezosLibrary.Account(accountAddr, signBoxHandle));
    }

    function update(TezosLibrary.Account account) override public {
        Terminal.print(0, "Update method");
        if(account.addr.hasValue()) {
            accountAddr = account.addr;
        }
        if(account.signBoxHandle.hasValue()) {
            signBoxHandle = account.signBoxHandle;
        }
    }

    function finish() override public {
        showMainMenu();
    }
}
