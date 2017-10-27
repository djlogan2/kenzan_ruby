module ErrorCode
  NONE = 0
  INVALID_USERNAME_OR_PASSWORD = 1
  NO_AUTHORIZATION_TOKEN = 2
  INVALID_AUTHORIZATION_TOKEN_PARSE_ERROR = 3
  INVALID_AUTHORIZATION_TOKEN_NO_BEARER = 4
  INVALID_AUTHORIZATION_TOKEN_INVALID_SIGNATURE = 5
  INVALID_AUTHORIZATION_HEADER_INVALID_ALGORITHM = 6
  INVALID_AUTHORIZATION_PAYLOAD_NO_ISSUER = 7
  INVALID_AUTHORIZATION_PAYLOAD_INVALID_ISSUER = 8
  INVALID_AUTHORIZATION_PAYLOAD_NO_ISSUED = 9
  INVALID_AUTHORIZATION_PAYLOAD_INVALID_ISSUED = 10
  INVALID_AUTHORIZATION_PAYLOAD_NO_EXPIRATION = 11
  INVALID_AUTHORIZATION_PAYLOAD_INVALID_EXPIRATION = 12
  INVALID_AUTHORIZATION_PAYLOAD_NO_USERNAME = 13
  INVALID_AUTHORIZATION_TOKEN_EXPIRED = 14
  NOT_AUTHORIZED_FOR_OPERATION = 15
  DUPLICATE_RECORD = 16
  CANNOT_DELETE_NONEXISTENT_RECORD = 17
  CANNOT_UPDATE_NONEXISTENT_RECORD = 18
  UNKNOWN_ERROR = 19
  CANNOT_INSERT_MISSING_FIELDS = 20
  CANNOT_INSERT_UNKNOWN_FIELDS = 21
end