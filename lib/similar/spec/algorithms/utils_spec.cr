require "../spec_helper"

describe Similar::Algorithms do
  describe ".unique" do
    it "test_unique" do
      # Test from Rust: test_unique()
      # let u = unique(&vec!['a', 'b', 'c', 'd', 'd', 'b'], 0..6)
      #   .into_iter()
      #   .map(|x| (*x.value(), x.original_index()))
      #   .collect::<Vec<_>>();
      # assert_eq!(u, vec![('a', 0), ('c', 2)]);
      lookup = ['a', 'b', 'c', 'd', 'd', 'b']
      result = Similar::Algorithms.unique(lookup, 0...6)
        .map { |x| {x.value, x.original_index} }
      result.should eq([{'a', 0}, {'c', 2}])
    end
  end

  describe ".common_prefix_len" do
    it "test_common_prefix_len" do
      # Test from Rust: test_common_prefix_len()
      # assert_eq!(
      #   common_prefix_len("".as_bytes(), 0..0, "".as_bytes(), 0..0),
      #   0
      # );
      Similar::Algorithms.common_prefix_len("".bytes, 0..0, "".bytes, 0..0).should eq(0)

      # assert_eq!(
      #   common_prefix_len("foobarbaz".as_bytes(), 0..9, "foobarblah".as_bytes(), 0..10),
      #   7
      # );
      Similar::Algorithms.common_prefix_len("foobarbaz".bytes, 0..9, "foobarblah".bytes, 0..10).should eq(7)

      # assert_eq!(
      #   common_prefix_len("foobarbaz".as_bytes(), 0..9, "blablabla".as_bytes(), 0..9),
      #   0
      # );
      Similar::Algorithms.common_prefix_len("foobarbaz".bytes, 0..9, "blablabla".bytes, 0..9).should eq(0)

      # assert_eq!(
      #   common_prefix_len("foobarbaz".as_bytes(), 3..9, "foobarblah".as_bytes(), 3..10),
      #   4
      # );
      Similar::Algorithms.common_prefix_len("foobarbaz".bytes, 3..9, "foobarblah".bytes, 3..10).should eq(4)
    end
  end

  describe ".common_suffix_len" do
    it "test_common_suffix_len" do
      # Test from Rust: test_common_suffix_len()
      # assert_eq!(
      #   common_suffix_len("".as_bytes(), 0..0, "".as_bytes(), 0..0),
      #   0
      # );
      Similar::Algorithms.common_suffix_len("".bytes, 0..0, "".bytes, 0..0).should eq(0)

      # assert_eq!(
      #   common_suffix_len("1234".as_bytes(), 0..4, "X0001234".as_bytes(), 0..8),
      #   4
      # );
      Similar::Algorithms.common_suffix_len("1234".bytes, 0..4, "X0001234".bytes, 0..8).should eq(4)

      # assert_eq!(
      #   common_suffix_len("1234".as_bytes(), 0..4, "Xxxx".as_bytes(), 0..4),
      #   0
      # );
      Similar::Algorithms.common_suffix_len("1234".bytes, 0..4, "Xxxx".bytes, 0..4).should eq(0)

      # assert_eq!(
      #   common_suffix_len("1234".as_bytes(), 2..4, "01234".as_bytes(), 2..5),
      #   2
      # );
      Similar::Algorithms.common_suffix_len("1234".bytes, 2..4, "01234".bytes, 2..5).should eq(2)
    end
  end

  describe "IdentifyDistinct" do
    it "test_int_hasher" do
      # Test from Rust: test_int_hasher()
      # let ih = IdentifyDistinct::<u8>::new(
      #   &["", "foo", "bar", "baz"][..],
      #   1..4,
      #   &["", "foo", "blah", "baz"][..],
      #   1..4,
      # );
      # assert_eq!(ih.old_lookup()[1], 0);
      # assert_eq!(ih.old_lookup()[2], 1);
      # assert_eq!(ih.old_lookup()[3], 2);
      # assert_eq!(ih.new_lookup()[1], 0);
      # assert_eq!(ih.new_lookup()[2], 3);
      # assert_eq!(ih.new_lookup()[3], 2);
      # assert_eq!(ih.old_range(), 1..4);
      # assert_eq!(ih.new_range(), 1..4);
      old = ["", "foo", "bar", "baz"]
      new = ["", "foo", "blah", "baz"]
      ih = Similar::Algorithms::IdentifyDistinct(UInt8).new(old, 1...4, new, 1...4)

      ih.old_lookup[1].should eq(0)
      ih.old_lookup[2].should eq(1)
      ih.old_lookup[3].should eq(2)
      ih.new_lookup[1].should eq(0)
      ih.new_lookup[2].should eq(3)
      ih.new_lookup[3].should eq(2)
      ih.old_range.should eq(1...4)
      ih.new_range.should eq(1...4)
    end
  end
end
