# encoding: UTF-8
require 'test_helper'

class DojosTest < ActionDispatch::IntegrationTest
  def setup
    @user = FactoryGirl.create(:user)
    @dojos, @valid_dojo = [], FactoryGirl.build(:dojo)
    (-5..5).each {|n| @dojos << FactoryGirl.create(:dojo, day: Date.today + n) }
  end

  def teardown
    super
    @dojos, @valid_dojo, @user = nil, nil, nil
  end

  test 'should require login to insert' do
    visit new_dojo_path
    assert_equal login_path, current_path
    assert find('h2').has_content?('Login'), 'Should be login page'
  end

  test 'should insert' do
    with @user do
      insert @valid_dojo
      assert find('h2').has_content?(@valid_dojo.local), "Should save with success"
    end
  end

  test 'should visit dojos page from edit page' do
    visit "/dojos/#{@dojos.first.id}"
    click_link('Voltar')
    assert_equal dojos_path, current_path, "Should go to list page"
  end

  test 'should back to homepage' do
    with @user do
      visit new_dojo_path
      click_link('Cancelar')
      assert find('h1').has_content?('Dojo, aonde?'), "Should back to homepage"
    end
  end

  test 'should show list of dojos that not happened with recent first' do
    @dojos.delete_if {|dojo| dojo.day < Date.today }

    visit dojos_path
    assert find('tbody tr:first')
          .has_content?(@dojos.last.local), "First should have recent date"
    assert find('tbody tr:last')
          .has_content?(@dojos.first.local), "Last should have older date"
  end

  test 'should show list of dojos that happened with the recent first' do
    @dojos.delete_if { |dojo| dojo.day >= Date.today }

    visit dojos_happened_path
    assert find('table tbody tr:first')
          .has_content?(@dojos.last.local), "First should have recent date"
    assert find('table tbody tr:last')
          .has_content?(@dojos.first.local), "First should have older date"
  end

  test 'should edit' do
    dojo = FactoryGirl.create(:dojo)
    with @user do
      new_local = 'Lugar secreto'
      visit edit_dojo_path(dojo)
      fill_in('Local', with: new_local)
      click_button('Salvar')
      assert find('h2')
            .has_content?(new_local),'Should edit and save with success'
    end
  end

  test 'should be invalid without a local' do
    @valid_dojo.local = nil
    assert_invalid @valid_dojo, "local é obrigatório"
  end

  test 'should be invalid without a day' do
    @valid_dojo.day = nil
    assert_invalid @valid_dojo, "dia é obrigatório"
  end

  test 'should be invalid with a previous day' do
    @valid_dojo.day = Date.today - 7
    assert_invalid @valid_dojo, "dias anteriores não são permitidos"
  end

  test 'should show dojo' do
    dojo = FactoryGirl.create :dojo
    visit dojo_path(dojo)
    assert find('h2').has_content?(dojo.local), "Should show title"
    assert page.has_content?("Local: #{dojo.local}"), "Should show local"
    assert page.has_content?("Dia: #{dojo.day}"), "Should show day"
    assert page.has_content?("Outras informações: #{dojo.info}"), "Should show info"
  end

  private
  def insert(dojo)
    visit new_dojo_path
    fill_in 'Dia', with: dojo.day
    fill_in 'Local', with: dojo.local
    fill_in 'Outras informações', with: dojo.info
    fill_in 'Link do Google Maps', with: dojo.gmaps_link
    click_button 'Salvar'
  end

  def assert_invalid(dojo, msg)
    with @user do
      insert dojo
      assert find('div#error_explanation')
            .has_content?(msg), "Should show #{msg}"
    end
  end
end
