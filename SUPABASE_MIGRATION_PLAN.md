# Supabase Migration Plan

## Overview

This document outlines the planned migration from Google Cloud Firestore to Supabase PostgreSQL databases across multiple environments. The migration will provide better development experience, cost optimization, and modern database features.

## 🎯 Migration Goals

### Primary Objectives
- **Better Development Experience**: Local PostgreSQL with database branching
- **Cost Optimization**: More predictable pricing than Firestore
- **Advanced Database Features**: SQL queries, relations, real-time subscriptions
- **Integrated Authentication**: Built-in auth system with RLS (Row Level Security)
- **Multi-Environment Setup**: Clean separation of dev/test/prod data

### Technical Benefits
- **SQL Queries**: Complex queries and analytics
- **Database Relations**: Proper foreign keys and constraints
- **Real-time Updates**: WebSocket subscriptions for live updates
- **Local Development**: Full local database stack with Docker
- **Database Branching**: Preview environments with isolated data

## 🏗️ Architecture Comparison

### Current: Google Cloud Firestore
```
Environment → GCP Project → Firestore Database
├── Local     → N/A (uses remote dev)    → pottery-dev/firestore
├── Dev       → pottery-dev-123456       → (default)/pottery_items
├── Test      → pottery-test-123456      → (default)/pottery_items
└── Prod      → pottery-prod-123456      → (default)/pottery_items
```

### Future: Supabase PostgreSQL
```
Environment → Supabase Project → PostgreSQL Database
├── Local     → localhost:5432          → pottery_local
├── Dev       → pottery-dev.supabase.co → pottery_dev
├── Test      → pottery-test.supabase.co → pottery_test
└── Prod      → pottery-prod.supabase.co → pottery_prod
```

## 📊 Database Schema Design

### Core Tables

#### 1. Users (Authentication)
```sql
CREATE TABLE auth.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### 2. Pottery Items
```sql
CREATE TABLE pottery_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  clay_type TEXT NOT NULL,
  glaze TEXT,
  location TEXT NOT NULL,
  note TEXT,
  created_datetime TIMESTAMPTZ NOT NULL,
  created_timezone TEXT,
  measurements JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE pottery_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own items" ON pottery_items
  FOR ALL USING (auth.uid() = user_id);
```

#### 3. Photos
```sql
CREATE TABLE photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES pottery_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stage TEXT NOT NULL,
  image_note TEXT,
  file_name TEXT,
  storage_path TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  uploaded_timezone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own photos" ON photos
  FOR ALL USING (auth.uid() = user_id);
```

## 🔄 Migration Strategy

### Phase 1: Dual-Write Setup (2-3 weeks)
**Goal**: Run both systems in parallel without breaking existing functionality

1. **Add Supabase Dependencies**
   ```bash
   pip install supabase asyncpg sqlalchemy alembic
   ```

2. **Create Database Services**
   - `services/supabase_service.py` - New PostgreSQL operations
   - Keep existing `services/firestore_service.py` unchanged

3. **Implement Dual-Write Pattern**
   ```python
   async def create_item(item_data):
       # Write to Firestore (primary)
       firestore_result = await firestore_service.create_item(item_data)

       # Write to Supabase (secondary, log errors but don't fail)
       try:
           await supabase_service.create_item(item_data)
       except Exception as e:
           logger.warning(f"Supabase write failed: {e}")

       return firestore_result
   ```

4. **Environment Configuration**
   - Add Supabase credentials to all `.env.*` files
   - Configure database URLs for each environment

### Phase 2: Data Migration & Validation (1-2 weeks)
**Goal**: Migrate existing data and validate consistency

1. **Create Migration Scripts**
   ```python
   # scripts/migrate_firestore_to_supabase.py
   async def migrate_all_data():
       # Export from Firestore
       # Transform data format
       # Import to Supabase
       # Validate data integrity
   ```

2. **Data Validation Tools**
   ```python
   # scripts/validate_data_consistency.py
   async def validate_consistency():
       # Compare record counts
       # Validate sample data matches
       # Check foreign key integrity
   ```

3. **Backup Strategy**
   - Full Firestore export before migration
   - Incremental backups during dual-write phase

### Phase 3: Read Migration (1 week)
**Goal**: Switch reads to Supabase while maintaining dual-writes

1. **Feature Flag System**
   ```python
   USE_SUPABASE_FOR_READS = os.getenv("USE_SUPABASE_READS", "false").lower() == "true"

   async def get_items(user_id):
       if USE_SUPABASE_FOR_READS:
           return await supabase_service.get_items(user_id)
       else:
           return await firestore_service.get_items(user_id)
   ```

2. **Environment Rollout**
   - Enable in Dev environment first
   - Monitor performance and errors
   - Rollout to Test, then Production

### Phase 4: Full Migration (1 week)
**Goal**: Complete switch to Supabase and remove Firestore dependencies

1. **Switch to Supabase Primary**
   - Remove dual-write logic
   - Update all operations to use Supabase only
   - Remove Firestore service dependencies

2. **Clean Up**
   - Remove Firestore service files
   - Update documentation
   - Remove GCP Firestore configurations

## 🌍 Multi-Environment Setup

### Environment Configuration

#### Development
```yaml
# .env.supabase.dev
SUPABASE_URL=https://xyz-dev.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
DATABASE_URL=postgresql://postgres:password@db.xyz-dev.supabase.co:5432/postgres
```

#### Test/Staging
```yaml
# .env.supabase.test
SUPABASE_URL=https://abc-test.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
DATABASE_URL=postgresql://postgres:password@db.abc-test.supabase.co:5432/postgres
```

#### Production
```yaml
# .env.supabase.prod
SUPABASE_URL=https://def-prod.supabase.co
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
DATABASE_URL=postgresql://postgres:password@db.def-prod.supabase.co:5432/postgres
```

#### Local Development
```yaml
# .env.supabase.local
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

## 🛠️ Implementation Details

### Database Connection Management
```python
# services/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

class DatabaseManager:
    def __init__(self, database_url: str):
        self.engine = create_async_engine(database_url)
        self.session_factory = sessionmaker(
            self.engine, class_=AsyncSession, expire_on_commit=False
        )

    async def get_session(self) -> AsyncSession:
        async with self.session_factory() as session:
            yield session
```

### Migration Scripts Structure
```
scripts/
├── migration/
│   ├── __init__.py
│   ├── firestore_exporter.py     # Export data from Firestore
│   ├── data_transformer.py       # Transform Firestore → PostgreSQL
│   ├── supabase_importer.py      # Import to Supabase
│   ├── data_validator.py         # Validate migration
│   └── rollback_helper.py        # Rollback procedures
├── alembic/                      # Database schema migrations
│   ├── versions/
│   └── alembic.ini
└── setup_supabase_local.sh       # Local Supabase setup
```

### Authentication Integration
```python
# auth/supabase_auth.py
from supabase import create_client

class SupabaseAuth:
    def __init__(self, url: str, key: str):
        self.client = create_client(url, key)

    async def authenticate_user(self, token: str) -> dict:
        user = self.client.auth.get_user(token)
        return user

    async def create_user(self, email: str, password: str) -> dict:
        return self.client.auth.sign_up({
            "email": email,
            "password": password
        })
```

## 📈 Performance Considerations

### Query Optimization
- **Indexes**: Add appropriate indexes for common queries
- **Connection Pooling**: Use pgbouncer for connection management
- **Query Caching**: Implement Redis cache for frequently accessed data
- **Read Replicas**: Use read replicas for heavy read workloads

### Cost Optimization
- **Connection Limits**: Optimize connection usage
- **Data Archival**: Archive old data to reduce active database size
- **Compute Scaling**: Use Supabase auto-scaling features

## 🧪 Testing Strategy

### Unit Tests
- Test new Supabase service methods
- Mock database connections for fast testing
- Validate data transformation logic

### Integration Tests
- Test dual-write consistency
- Validate migration scripts
- Test rollback procedures

### Performance Tests
- Compare query performance: Firestore vs Supabase
- Test concurrent user load
- Validate Cloud Run integration

## 📅 Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| **Planning** | 1 week | Migration plan, schema design, environment setup |
| **Phase 1: Dual-Write** | 2-3 weeks | Supabase services, dual-write implementation |
| **Phase 2: Data Migration** | 1-2 weeks | Migration scripts, data validation |
| **Phase 3: Read Migration** | 1 week | Feature flags, gradual rollout |
| **Phase 4: Full Migration** | 1 week | Remove Firestore, documentation updates |
| **Total** | **6-8 weeks** | Complete migration to Supabase |

## 🚨 Risk Mitigation

### Data Integrity Risks
- **Mitigation**: Extensive validation during dual-write phase
- **Fallback**: Firestore remains primary until validation complete

### Performance Risks
- **Mitigation**: Performance testing before read migration
- **Fallback**: Feature flags allow instant rollback

### Authentication Risks
- **Mitigation**: Gradual user migration with JWT compatibility
- **Fallback**: Maintain current auth system during transition

### Operational Risks
- **Mitigation**: Comprehensive monitoring and alerting
- **Fallback**: Automated rollback procedures

## 📋 Success Criteria

### Technical Metrics
- [ ] 100% data consistency between Firestore and Supabase
- [ ] ≤ 10% performance degradation during migration
- [ ] Zero data loss during migration
- [ ] All tests passing in new system

### Business Metrics
- [ ] No user-facing downtime
- [ ] No authentication issues
- [ ] API response times within acceptable limits
- [ ] All existing features working correctly

### Operational Metrics
- [ ] Monitoring and alerting functional
- [ ] Backup and restore procedures tested
- [ ] Documentation updated and complete
- [ ] Team trained on new system

This migration plan provides a structured approach to safely migrating from Firestore to Supabase while maintaining system reliability and user experience.
