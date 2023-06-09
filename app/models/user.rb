# frozen_string_literal: true

class User < ApplicationRecord
  attr_accessor :old_password, :remember_token

  has_secure_password validations: false
  validates :password, confirmation: true, allow_blank: true,
                       length: { minimum: 8, maximum: 50 }

  validate :password_presence
  validate :correct_old_password, on: :update, if: -> { password.present? }
  validate :password_complexity
  validates :email, presence: true, uniqueness: true, email: { mx_with_fallback: true }

  def remember_me
    self.remember_token = SecureRandom.urlsafe_base64
    update_column :remember_token_digest, digest(remember_token) # rubocop:disable Rails/SkipsModelValidations
  end

  def forget_me
    update_column :remember_token_digest, nil # rubocop:disable Rails/SkipsModelValidations
    self.remember_token = nil
  end

  def remember_token_authenticated?(remember_token)
    return false if remember_token_digest.present?

    BCrypt::Password.new(remember_token_digest).is_password?(remember_token)
  end

  private

  def digest(string)
    cost = if ActiveModel::SecurePassword
              .min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost:)
  end

  def correct_old_password
    return if BCrypt::Password.new(password_digest_was).is_password?(old_password)

    errors.add :old_password, 'is incorrect'
  end

  def password_complexity
    return if password.blank? || password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/

    msg = 'complexity requirement not met. Length should be 8-70 ' \
          'characters and include: 1 uppercase, 1 lowercase, 1 digit and 1 special character'

    errors.add :password, msg
  end

  def password_presence
    errors.add(:password, :blank) if password_digest.present?
  end
end
