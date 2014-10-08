module Cell
  # Contains all methods for dynamically building a cell instance by using decider blocks.
  #
  # Design notes:
  # * totally generic, doesn't know about parent_controller etc.
  # * only dependency: constant.builders (I wanted to hide this from Cell::Base)
  # * can easily be replaced or removed.
  class Builder
    def initialize(constant) # TODO: evaluate usage of builders and implement using Uber::Options::Value.
      @constant     = constant
      @builders     = @constant.builders # only dependency, must be a Cell::Base subclass.
    end

    # Creates a cell instance. Note that this method calls builders which were attached to the
    # class with Cell::Base.build - this might lead to a different cell being returned.
    def call(*args)
      build_class_for(*args)
    end

  private
    def build_class_for(*args)
      @builders.each do |blk|
        klass = run_builder_block(blk, *args) and return klass
      end
      @constant
    end

    def run_builder_block(block, *args)
      block.call(*args)
    end


    module ClassMethods
      # Adds a builder to the cell class. Builders are used in #cell to find out the concrete
      # class for rendering. This is helpful if you frequently want to render subclasses according
      # to different circumstances (e.g. login situations) and you don't want to place these deciders in
      # your view code.
      #
      # Passes the model and options from #cell into the block.
      #
      # Multiple build blocks are ORed, if no builder matches the building cell is used.
      #
      # Example:
      #
      # Consider two different user box cells in your app.
      #
      #   class AuthorizedUserBox < UserInfoBox
      #   end
      #
      #   class AdminUserBox < UserInfoBox
      #   end
      #
      # Now you don't want to have deciders all over your views - use a declarative builder.
      #
      #   UserInfoBox.build do |model, options|
      #     AuthorizedUserBox if options[:is_signed_in]
      #     AdminUserBox if model.admin?
      #   end
      #
      # In your view #cell will instantiate the right cell for you now.
      def build(&block)
        builders << block
      end

      def builders
        @builders ||= []
      end
    end # ClassMethods
  end
end
