const https = require("https"),
      url = require("url"),
      path = require("path"),
      fs = require("fs"),
      port = 8000,
      { spawn } = require("child_process");

const options = {
  key: fs.readFileSync("/etc/letsencrypt/live/kemuri.ddns.net/privkey.pem"),
  cert: fs.readFileSync("/etc/letsencrypt/live/kemuri.ddns.net/fullchain.pem")
};

https.createServer(options, (request, response) => {
  const cmd = spawn("./nbt2json", [
    "--java",
    "--in",
    "/home/ubuntu/KemuriCraft/world/playerdata/6e1be877-4355-4be1-aa10-bc691d4b64b2.dat"
  ]);

  let out = "";
  cmd.stdout.on("data", data => {
    out += data;
  });

  cmd.on("close", () => {
    let nbt = JSON.parse(out).nbt;
    let j = jsoncomplete(nbt, 10)[""];
    let ender = j.EnderItems;
    let inventory = j.Inventory;
    let txt = "<html><head>";
    txt += "<style>div{margin-left:40px}</style>"
    txt += "</head><body>";
    txt += "<h1>" + j.bukkit.lastKnownName + "</h1>";
    txt += "Inventory<div>" +
           inv(inventory) + "</div>" +
           "Enderchest<div>" +
           inv(ender) + "</div>";
    txt += "</body></html>";
    response.writeHead(200);
    response.write(txt, "binary");
    response.end();
  });

}).listen(port);

function ii(id){
  id = id.split(":")[1].split("_").join(" ");
  id = id[0].toUpperCase() + id.slice(1);
  return id;
}

function inv(data){
  let txt = "";
  for(let i of data){
    let id = ii(i.id);
    txt += i.Count + "x " + id + "<br>";
    if(i.tag){
      txt += "<div>";
      if("BlockEntityTag" in i.tag)
        txt += "Container<div>" +
               inv(i.tag.BlockEntityTag.Items) + "</div>";
      if("Damage" in i.tag)
        txt += "Damage " + i.tag.Damage + "<br>";
      if("Enchantments" in i.tag){
        txt += "Enchantments<div>";
        for(let enc of i.tag.Enchantments)
          txt += enc.lvl + " " + ii(enc.id) + "<br>";
        txt += "</div>";
      }
      txt += "</div>";
    }
  }
  return txt;
}

function jsoncomplete(nbt,type){
  switch(type){
    case undefined:
      console.log("error");
      return "";
      break;
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 11:
    case 12:
      return nbt;
      break
    case 9:
      switch(nbt.tagListType){
        case 5:
        case 6:
        case 8:
          return nbt.list;
          break;
        case 10:
          let j = [];
          for(let v of nbt.list)
            j.push(jsoncomplete(v, 10));
          return j;
          break;
      }
      break;
    case 10:
      let j = {};
      for(let v of nbt)
        j[v.name] = jsoncomplete(v.value, v.tagType);
      return j;
      break;
  }
}

console.log("Static file server running at\n  => http://localhost:" + port + "/\nCTRL + C to shutdown");
