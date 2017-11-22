module JsonApiController
  shared_examples 'an app IDM endpoint' do
    subject { get :index }

    context 'without authentication' do
      it { is_expected.to have_http_status(:unauthorized), "response.code: #{response.code}" }
    end

    context 'with authentication' do
      let(:config) { Maestrano.configs.values.first }
      before { @request.env['HTTP_AUTHORIZATION'] = 'Basic ' + Base64.encode64("#{config.param('api.id')}:#{config.param('api.key')}") }

      it { is_expected.to have_http_status(:ok), "response.code: #{response.code}" }
    end
  end
end
