module TicTac
  module Repos
    User = Struct.new(:name, :pub_key)

    class Users

      attr_reader :ipfs_connection_object

      def initialize(ipfs_connection_object)
        @ipfs_connection_object = ipfs_connection_object
      end

      # user: TicTac::Repos::User
      def create(user)
        # decrypt name w/ public key
        # uniqueness of name.
        # write new user to users log
      end

      def update(user, authentication_object)
        # publish public key change for user
      end

      def get(name: nil, pub_key: nil)
        # find matching user, return User object.
      end
    end
  end
end
