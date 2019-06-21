#include <iostream>
#include <thread>
#include <chrono>
#include <fstream>
#include <cstdlib>
#include <memory>
#include <string>

#include <libtorrent/session.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/bencode.hpp>
#include <libtorrent/torrent_status.hpp>
#include <libtorrent/read_resume_data.hpp>
#include <libtorrent/write_resume_data.hpp>
#include <libtorrent/error_code.hpp>
#include <libtorrent/magnet_uri.hpp>
#include <libtorrent/entry.hpp>
#include <libtorrent/torrent_info.hpp>

#include <grpcpp/grpcpp.h>

using clk = std::chrono::steady_clock;

#include "helloworld.grpc.pb.h"
#include "main.h"

using grpc::Server;
using grpc::ServerBuilder;
using grpc::ServerContext;
using grpc::Status;
using helloworld::HelloRequest;
using helloworld::HelloReply;
using helloworld::Greeter;

char const* state(lt::torrent_status::state_t s) {
  switch(s) {
    case lt::torrent_status::checking_files: return "checking";
    case lt::torrent_status::downloading_metadata: return "dl metadata";
    case lt::torrent_status::downloading: return "downloading";
    case lt::torrent_status::finished: return "finished";
    case lt::torrent_status::seeding: return "seeding";
    case lt::torrent_status::allocating: return "allocating";
    case lt::torrent_status::checking_resume_data: return "checking resume";
    default: return "<>";
  }
}

void torrent(std::string filename) {
  lt::session s;
  lt::add_torrent_params p;
  p.save_path = "./";
  p.ti = std::make_shared<lt::torrent_info>(filename);
  s.add_torrent(p);
  char a;
  int ret = std::scanf("%c\n", &a);
  (void)ret;
}

void magnet(std::string url) {
  lt::settings_pack pack;
  pack.set_int(lt::settings_pack::alert_mask
    , lt::alert::error_notification
    | lt::alert::storage_notification
    | lt::alert::status_notification);

  lt::session ses(pack);
  clk::time_point last_save_resume = clk::now();

  // load resume data from disk and pass it in as we add the magnet link
  const char* resumeFilename = ".resume_file";
  std::ifstream resumeFile(resumeFilename, std::ios_base::binary);
  lt::add_torrent_params atp;
  if (resumeFile.good()) {
    std::cout << "Resuming" << std::endl;
      resumeFile.unsetf(std::ios_base::skipws);
      std::vector<char> buf{std::istream_iterator<char>(resumeFile), std::istream_iterator<char>()};
      atp = lt::read_resume_data(buf);
  }
  lt::add_torrent_params magnet = lt::parse_magnet_uri(url);
  if (atp.info_hash != magnet.info_hash) {
    atp = std::move(magnet);
  }
  atp.save_path = "."; // save in current dir
  ses.async_add_torrent(std::move(atp));

  // this is the handle we'll set once we get the notification of it being
  // added
  lt::torrent_handle h;
  for (;;) {
    std::vector<lt::alert*> alerts;
    ses.pop_alerts(&alerts);

    for (lt::alert const* a : alerts) {
      if (auto at = lt::alert_cast<lt::add_torrent_alert>(a)) {
        h = at->handle;
      }
      // if we receive the finished alert or an error, we're done
      if (lt::alert_cast<lt::torrent_finished_alert>(a)) {
        h.save_resume_data();
        goto done;
      }
      if (lt::alert_cast<lt::torrent_error_alert>(a)) {
        std::cout << a->message() << std::endl;
        goto done;
      }

      // when resume data is ready, save it
      if (auto rd = lt::alert_cast<lt::save_resume_data_alert>(a)) {
        std::ofstream of(".resume_file", std::ios_base::binary);
        of.unsetf(std::ios_base::skipws);
        auto const b = write_resume_data_buf(rd->params);
        of.write(b.data(), b.size());
      }

      if (auto st = lt::alert_cast<lt::state_update_alert>(a)) {
        if (st->status.empty()) continue;

        // we only have a single torrent, so we know which one
        // the status is for
        lt::torrent_status const& s = st->status[0];
        std::cout << "\r" << state(s.state) << " "
          << (s.download_payload_rate / 1000) << " kB/s "
          << (s.total_done / 1000) << " kB ("
          << (s.progress_ppm / 10000) << "%) downloaded\x1b[K";
        std::cout.flush();
      }
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(200));

    // ask the session to post a state_update_alert, to update our
    // state output for the torrent
    ses.post_torrent_updates();

    // save resume data once every 30 seconds
    if (clk::now() - last_save_resume > std::chrono::seconds(30)) {
      h.save_resume_data();
      last_save_resume = clk::now();
    }
  }

  // TODO: ideally we should save resume data here

done:
  std::cout << "\ndone, shutting down" << std::endl;
}

// Logic and data behind the server's behavior.
class GreeterServiceImpl final : public Greeter::Service {
  Status SayHello(ServerContext* context, const HelloRequest* request, HelloReply* reply) override {
    std::string prefix("Hello ");
    reply->set_message(prefix + request->name());
    return Status::OK;
  }
};

void runServer() {
  std::string server_address("0.0.0.0:50051");
  GreeterServiceImpl service;

  ServerBuilder builder;
  // Listen on the given address without any authentication mechanism.
  builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
  // Register "service" as the instance through which we'll communicate with
  // clients. In this case it corresponds to an *synchronous* service.
  builder.RegisterService(&service);
  // Finally assemble the server.
  std::unique_ptr<Server> server(builder.BuildAndStart());
  std::cout << "Server listening on " << server_address << std::endl;

  // Wait for the server to shutdown. Note that some other thread must be
  // responsible for shutting down the server for this call to ever return.
  server->Wait();
}

int main(int argc, const char* argv[]) try {
    if (argc < 3) {
        runServer();
    } else {
        std::string type(argv[1]);
        std::string data(argv[2]);

        if (type == "torrent") {
            torrent(data);
        } else if (type == "magnet") {
            magnet(data);
        }
    }
}
catch (std::exception const& e) {
  std::cerr << "ERROR: " << e.what() << "\n";
}

