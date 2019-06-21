#include <cassert>
#include <iostream>
#include <unistd.h>
#include <stdio.h>
#include <signal.h>
#include <chrono>
#include <thread>
#include <grpcpp/grpcpp.h>
#include "helloworld.grpc.pb.h"

using namespace std;

pid_t startMainProgram(const char* mainProgramPath) {
    pid_t pid = fork();
	if (pid == 0) {
	    // child
	    execl(mainProgramPath, (char*)NULL);
	} else if (pid < 0) {
	    // error
	} else {
        // parent
	}
	return pid;
}

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;
using helloworld::HelloRequest;
using helloworld::HelloReply;
using helloworld::Greeter;

class GreeterClient {
 public:
  GreeterClient(std::shared_ptr<Channel> channel)
      : stub_(Greeter::NewStub(channel)) {}

  // Assembles the client's payload, sends it and presents the response back
  // from the server.
  std::string SayHello(const std::string& user) {
    // Data we are sending to the server.
    HelloRequest request;
    request.set_name(user);

    // Container for the data we expect from the server.
    HelloReply reply;

    // Context for the client. It could be used to convey extra information to
    // the server and/or tweak certain RPC behaviors.
    ClientContext context;

    // The actual RPC.
    Status status = stub_->SayHello(&context, request, &reply);

    // Act upon its status.
    if (status.ok()) {
      return reply.message();
    } else {
      std::cout << status.error_code() << ": " << status.error_message()
                << std::endl;
      return "RPC failed";
    }
  }

 private:
  std::unique_ptr<Greeter::Stub> stub_;
};


int main(int argc, const char* argv[]) {
    pid_t mainProgramPid = startMainProgram(argv[1]);

    this_thread::sleep_for(chrono::milliseconds(2000));
    GreeterClient greeter(grpc::CreateChannel(
          "localhost:50051", grpc::InsecureChannelCredentials()));
      std::string user("world");
      std::string reply = greeter.SayHello(user);
    std::cout << "Greeter received: " << reply << std::endl;

    kill(mainProgramPid, SIGKILL);
    return 0;
}

