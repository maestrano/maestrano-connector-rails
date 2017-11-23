module SharedPunditExample
  shared_examples 'a model scoped to the tenant' do
    let(:klass) { described_class.to_s.gsub('Policy', '').constantize }
    let(:scope) { klass.all }

    subject { described_class::Scope.new('default', scope).resolve }

    context 'when scoped to the right tenant' do
      it { is_expected.to eq([instance1]) }
    end
  end
end
