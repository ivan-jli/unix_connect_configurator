use structopt::StructOpt;
use cmd_lib::{info, warn, run_cmd, CmdResult, FunResult};
use regex::Regex;
use std::{thread, time};

/// Search for a pattern in a file and display the lines that contain it.
#[derive(Debug, StructOpt)]
struct Cli {
    interface: String,
}

fn main() -> CmdResult {
    println!("unixConnectConfigurator begin");
    let interface = Cli::from_args().interface;
    //todo - add a rule only for mDNS
    run_cmd!(iptables -F ; iptables -P INPUT ACCEPT);
    run_cmd!("avahi-autoipd -D {}", interface); 
    run_cmd!("systemctl start avahi-daemon");
    let mut ifconfigOutput;
    let mut i = 8;
    let mut ifconfigOutputResult = String::new();
    loop
    {
        ifconfigOutput = run_cmd!("ifconfig {}|grep inet", interface);
        ifconfigOutputResult = match ifconfigOutput
        {
            Ok(t) => {
                break;
                String::from(t),
            },
            Err(e) => 
            {
                println!("waiting till the interface is configured, {}", e);
                thread::sleep(time::Duration::from_millis(1000));
                i-=1;
                if(i == 0)
                {
                    panic!("failed to run configuration. The expected ip address not found");
                }
            }
        }
    } 
//overriding a bug I met in Fedora 32 (?), the routing (?) didn't function properly unless a real
//physical adapter (instead of the virtual Avahi one) is configured. What I remember is that the
//packets from the client went with a wrong source IP address.
    let re = Regex::new(r"(^\s*inet )(\d*\.\d*\.\d*\.\d*)").unwrap();

    let ipAddrStr = re.captures(&ifconfigOutputResult).unwrap().get(2).unwrap().as_str();
    println!("IP Address: {:?}", ipAddrStr);

    run_cmd!("echo IP_ADDR: {:?}", ipAddrStr); 
    let re_match_phy_interface = Regex::new(r"([a-zA-Z0-9]*)").unwrap();
    let phy_interface = re_match_phy_interface.captures(&interface).unwrap().get(1).unwrap().as_str();
    println!("PHY IF: {}", phy_interface);
    run_cmd!("sudo ifconfig {} down", interface);
    run_cmd!("sudo ifconfig {} {}", phy_interface, ipAddrStr);
    //run_cmd!("ifconfig 
    Ok(())
}
