# IP Registry Smart Contract

## Overview

The IP Registry Smart Contract is a decentralized system designed to manage and track intellectual property (IP) assets on the blockchain. This contract allows creators to register, update, and manage the status of their intellectual property in a transparent and secure manner.

## Features

- **IP Registration**: Register intellectual property with detailed metadata
- **IP Types Support**: Categorize IP assets as music, video, text, software, or image
- **Status Tracking**: Mark IP assets as active, disputed, or archived
- **Creator Attribution**: Automatically track creators and their IP portfolio
- **Metadata Management**: Update IP details while maintaining creation history
- **Ownership Verification**: Only the original creator can modify their IP records

## Smart Contract Details

### Data Structures

1. **IP Assets**: Stores comprehensive information about each IP, including:
   - Name (limited to 100 ASCII characters)
   - Description (limited to 500 ASCII characters) 
   - IP Type (music, video, text, software, or image)
   - Creator (the principal who registered the IP)
   - Creation Date (timestamp from blockchain)
   - Status (active, disputed, or archived)
   - Metadata URI (optional, limited to 256 ASCII characters)

2. **Creator IP Tracking**: Maps creators to all their registered IP assets

### Public Functions

#### `register-ip`
Registers a new intellectual property asset.

```clarity
(define-public (register-ip
                (name (string-ascii 100))
                (description (string-ascii 500))
                (ip-type (string-ascii 20))
                (metadata-uri (optional (string-ascii 256)))
              )
```

Parameters:
- `name`: The name of the IP asset (max 100 ASCII characters)
- `description`: Detailed description of the IP (max 500 ASCII characters)
- `ip-type`: Type of the IP (must be one of the predefined types)
- `metadata-uri`: Optional URI pointing to additional metadata

Returns:
- `(ok uint)`: The ID of the newly registered IP

#### `update-ip-metadata`
Updates the metadata of an existing IP asset.

```clarity
(define-public (update-ip-metadata
                (ip-id uint)
                (name (optional (string-ascii 100)))
                (description (optional (string-ascii 500)))
                (metadata-uri (optional (string-ascii 256)))
              )
```

Parameters:
- `ip-id`: The ID of the IP to update
- `name`: Optional new name (if none provided, existing name is preserved)
- `description`: Optional new description
- `metadata-uri`: Optional new metadata URI

Returns:
- `(ok bool)`: Success indicator

#### `update-ip-status`
Updates the status of an IP asset.

```clarity
(define-public (update-ip-status (ip-id uint) (new-status (string-ascii 20)))
```

Parameters:
- `ip-id`: The ID of the IP to update
- `new-status`: The new status (must be one of the predefined statuses)

Returns:
- `(ok bool)`: Success indicator

### Read-Only Functions

#### `get-ip`
Retrieves detailed information about a specific IP asset.

```clarity
(define-read-only (get-ip (ip-id uint)))
```

Parameters:
- `ip-id`: The ID of the IP to retrieve

Returns:
- IP data or `none` if not found

#### `get-creator-ips`
Gets all IPs created by a specific user.

```clarity
(define-read-only (get-creator-ips (creator principal)))
```

Parameters:
- `creator`: The principal ID of the creator

Returns:
- List of IP IDs created by the specified principal

#### `ip-exists?`
Checks if an IP with a specific ID exists.

```clarity
(define-read-only (ip-exists? (ip-id uint)))
```

Parameters:
- `ip-id`: The ID of the IP to check

Returns:
- `true` if the IP exists, `false` otherwise

## Error Codes

- `ERR-NOT-AUTHORIZED` (u100): The caller is not authorized to perform the operation
- `ERR-ALREADY-EXISTS` (u101): The IP already exists
- `ERR-INVALID-STATUS` (u102): The status provided is not valid
- `ERR-NOT-FOUND` (u103): The IP could not be found
- `ERR-METADATA-TOO-LONG` (u104): The metadata exceeds the character limit
- `ERR-INVALID-TYPE` (u105): The IP type provided is not valid
- `ERR-TOO-MANY-IPS` (u106): The creator has reached the maximum number of IPs (100)

## IP Types

The contract supports the following IP types:
- `music`: Musical compositions, songs, or audio works
- `video`: Video content, films, or visual media
- `text`: Written works, articles, or textual content
- `software`: Computer code, applications, or software programs
- `image`: Images, photographs, or visual artwork

## IP Status Values

An IP asset can have one of the following statuses:
- `active`: The IP is actively managed and claimed
- `disputed`: There is a dispute regarding the IP ownership or rights
- `archived`: The IP has been archived (inactive but preserved)

## Usage Limitations

- Each creator can register up to 100 IP assets
- Text fields have character limits to prevent data bloat
- Only the original creator can modify their IP assets

## Implementation Notes

This contract uses Clarity's native data structures and type system to ensure data integrity and security. The contract maintains counters and maps to efficiently track and retrieve IP assets, ensuring that all operations are performed with proper authorization.